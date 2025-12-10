#!/usr/bin/env bash
# File: build-ohos.sh
# 功能：自动切换 OHOS 工具链 + 多架构 Go/CGo 编译

set -euo pipefail

# =======================
# 可自定义配置
# =======================
OHOS_SDK="/mnt/d/SDK/Ubuntu/HarmonyOS/command-line-tools/sdk/default/openharmony/native"
TOOLCHAIN_ROOT="${OHOS_SDK}/llvm"
SYSROOT="${OHOS_SDK}/sysroot"

CACHE_FILE="${HOME}/.ohos_toolchain.cache"

# 你想编译的架构（可以自己加）
TARGETS=(arm64-v8a armeabi-v7a)

# Go module 入口
GO_SRC="cgo.go"
OUT_ROOT="./build/v2"
# =======================


BIN_DIR="${TOOLCHAIN_ROOT}/bin"

# 自动扫描可用 *-ohos-clang 前缀
readarray -t PREFIXES < <(
  find "${BIN_DIR}" -type f -executable -name '*-ohos-clang' \
  | sed -E 's|.*/||; s|-clang$||' | sort -u
)

if ((${#PREFIXES[@]} == 0)); then
  echo "未找到任何 *-ohos-clang，请检查路径：${BIN_DIR}" >&2
  exit 1
fi

# 彩色输出
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

# ========== 工具链环境设置部分 ==========
set_toolchain(){
  local prefix=$1

  export OHOS_TOOLCHAIN_PREFIX="${prefix}"
  export OHOS_TOOLCHAIN_PATH="${BIN_DIR}"

  export CC="${BIN_DIR}/${prefix}-clang"
  export CXX="${BIN_DIR}/${prefix}-clang++"
  export AR="${BIN_DIR}/${prefix}-ar"
  export RANLIB="${BIN_DIR}/${prefix}-ranlib"
  export STRIP="${BIN_DIR}/${prefix}-strip"
  export OBJCOPY="${BIN_DIR}/${prefix}-objcopy"
  export OBJDUMP="${BIN_DIR}/${prefix}-objdump"
  export READELF="${BIN_DIR}/${prefix}-readelf"

  # PATH 插前面
  if [[ ":$PATH:" != *":${BIN_DIR}:"* ]]; then
    export PATH="${BIN_DIR}:$PATH"
  fi

  echo "${green}已切换至工具链：${prefix}${reset}"
}

interactive_select_toolchain(){
  echo "${yellow}检测到以下 OpenHarmony 工具链：${reset}"
  for i in "${!PREFIXES[@]}"; do
    printf "  %s) %s\n" "$((i+1))" "${PREFIXES[i]}"
  done

  local last=
  [[ -f "$CACHE_FILE" ]] && last=$(<"$CACHE_FILE")

  local prompt="${yellow}请选择 (1-${#PREFIXES[@]})"
  [[ -n "$last" ]] && prompt+="，直接回车用之前的 [$last]"
  prompt+="${reset}："

  read -rp "$prompt" sel
  [[ -z "$sel" && -n "$last" ]] && sel="$last"

  if ! [[ "$sel" =~ ^[0-9]+$ ]] || (( sel < 1 || sel > ${#PREFIXES[@]} )); then
    echo "${red}无效选择${reset}" >&2
    exit 1
  fi

  local prefix=${PREFIXES[$((sel-1))]}
  echo "$prefix" > "$CACHE_FILE"
  set_toolchain "$prefix"
}

# ========== Go 多 ABI 编译 ==========
function build_for_abi() {
  local abi=$1
  echo "${yellow}开始编译 ABI: ${abi}${reset}"

  case "$abi" in
    arm64-v8a)
      export GOARCH=arm64
      export GOOS=android   # ohos 目前必须用 android
      TARGET_TRIPLE=aarch64-linux-ohos
      ;;
    armeabi-v7a)
      export GOARCH=arm
      export GOOS=android
      TARGET_TRIPLE=arm-linux-ohos
      ;;
    x86_64)
      export GOARCH=amd64
      export GOOS=android
      TARGET_TRIPLE=x86_64-linux-ohos
      ;;
    *)
      echo "${red}未知 ABI: $abi${reset}"
      exit 1
      ;;
  esac

  export CGO_ENABLED=1

  export CGO_CFLAGS="-g -O2 --target=${TARGET_TRIPLE} --sysroot=${SYSROOT}"
  export CGO_LDFLAGS="--target=${TARGET_TRIPLE} -fuse-ld=lld --sysroot=${SYSROOT}"

  mkdir -p "${OUT_ROOT}/${abi}"

  go build -buildmode=c-shared -v -x \
    -o "${OUT_ROOT}/${abi}/libhamary.so" \
    "${GO_SRC}"

  echo "${green}[OK] ${abi} 编译完成 → ${OUT_ROOT}/${abi}/libhamary.so${reset}"
}

# ========== 入口 ==========
echo "${yellow}=== 选择 OpenHarmony 工具链 ===${reset}"
interactive_select_toolchain

echo "${yellow}=== 开始编译所有 ABI ===${reset}"
for abi in "${TARGETS[@]}"; do
  build_for_abi "$abi"
done

echo "${green}🎉 所有 ABI 编译成功！输出目录：${OUT_ROOT}${reset}"
