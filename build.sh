#!/usr/bin/env bash
# ==========================================================
#  ohos-go-build.sh —— 一键切换 OpenHarmony 工具链并交叉编译 Go so
# ==========================================================

# ======  用户可改配置  ======
# 1. 工具链根目录（改成你贴出的那个路径）
TOOLCHAIN_ROOT="/mnt/d/SDK/Ubuntu/HarmonyOS/command-line-tools/sdk/default/openharmony/native/llvm"
# 2. 存放上次选择的缓存
CACHE_FILE="${HOME}/.ohos_toolchain.cache"
# 3. Go 编译参数（需要时自行改）
GO_BUILD_ARG="-buildmode=c-shared -v"
GO_OUTPUT="./build/arm64-v8a/libhamary.so"
GO_PACKAGE="./cgo"
# ============================

BIN_DIR="${TOOLCHAIN_ROOT}/bin"
# ---- 扫描前缀 ----
readarray -t PREFIXES < <(
  find "${BIN_DIR}" -type f -executable -name '*-ohos-clang' |
  sed -E 's|.*/||; s|-clang$||' | sort -u
)
if ((${#PREFIXES[@]} == 0)); then
  echo "未能在 ${BIN_DIR} 找到任何 *-ohos-clang 工具链，请检查 TOOLCHAIN_ROOT" >&2
  exit 1
fi

# ---- 彩色 ----
red=$(tput setaf 1) green=$(tput setaf 2) yellow=$(tput setaf 3) reset=$(tput sgr0)

# ----------------------------------------------------------
#  下面函数基本保持你原脚本逻辑不变
# ----------------------------------------------------------
list_env(){
  echo "${green}当前工具链+Go交叉变量：${reset}"
  env | grep -E '^(OHOS_|CC|CXX|AR|RANLIB|STRIP|PATH|GOARCH|GOOS|CGO|LLVM)' | sed 's/^/  /'
}

reset_env(){
  unset OHOS_TOOLCHAIN_PREFIX OHOS_TOOLCHAIN_PATH
  unset CC CXX AR RANLIB STRIP OBJCOPY OBJDUMP READELF LD LLVM_CONFIG
  unset GOARCH GOOS CGO_ENABLED CGO_CFLAGS CGO_LDFLAGS
  export PATH=$(echo "$PATH" | sed "s|${BIN_DIR}:||g")
  echo "${yellow}已恢复系统默认工具链${reset}"
}

# 设置工具链 **并** 导出 Go 交叉编译所需变量
set_toolchain(){
  local idx=$1
  local prefix=${PREFIXES[idx]}
  export OHOS_TOOLCHAIN_PREFIX="${prefix}"
  export OHOS_TOOLCHAIN_PATH="${BIN_DIR}"

  # --- 常规交叉工具 ---
  export CC="${BIN_DIR}/${prefix}-clang"
  export CXX="${BIN_DIR}/${prefix}-clang++"
  export AR="${BIN_DIR}/${prefix}-ar"
  export RANLIB="${BIN_DIR}/${prefix}-ranlib"
  export STRIP="${BIN_DIR}/${prefix}-strip"
  export OBJCOPY="${BIN_DIR}/${prefix}-objcopy"
  export OBJDUMP="${BIN_DIR}/${prefix}-objdump"
  export READELF="${BIN_DIR}/${prefix}-readelf"
  export LD="${BIN_DIR}/lld"          # lld 链接器
  export LLVM_CONFIG="${BIN_DIR}/llvm-config"

  # --- Go 交叉参数 ---
  export GOARCH=arm64
  export GOOS=android                 # 如果你的 OHOS 目标就是 android 风格
  export CGO_ENABLED=1
  export CGO_CFLAGS="-g -O2 $( $LLVM_CONFIG --cflags ) --target=aarch64-linux-ohos --sysroot=${TOOLCHAIN_ROOT}/sysroot"
  export CGO_LDFLAGS="--target=aarch64-linux-ohos -fuse-ld=lld"

  # 保证 bin 目录在 PATH 最前
  if [[ ":$PATH:" != *":${BIN_DIR}:"* ]]; then
    export PATH="${BIN_DIR}:$PATH"
  fi
  echo "${green}已切换至 ${prefix} 工具链，并导出 Go 交叉变量${reset}"
}

interactive_select(){
  echo "${yellow}检测到以下 OpenHarmony 工具链：${reset}"
  for i in "${!PREFIXES[@]}"; do
    printf "  %s) %s\n" "$((i+1))" "${PREFIXES[i]}"
  done
  local last=
  [[ -f "$CACHE_FILE" ]] && last=$(<"$CACHE_FILE")
  local prompt="${yellow}请选择 (1-${#PREFIXES[@]})"
  [[ -n "$last" ]] && prompt+="，直接回车重选 [$last]"
  prompt+="${reset}："
  read -rp "$prompt" sel
  [[ -z "$sel" && -n "$last" ]] && sel="$last"
  if ! [[ "$sel" =~ ^[0-9]+$ ]] || (( sel < 1 || sel > ${#PREFIXES[@]} )); then
    echo "${red}无效选择${reset}" >&2
    return 1
  fi
  set_toolchain "$((sel-1))"
  echo "${PREFIXES[$((sel-1))]}" > "$CACHE_FILE"
}

# 直接帮你 go build
do_go_build(){
  echo "${green}开始 Go 交叉编译…${reset}"
  mkdir -p "$(dirname "$GO_OUTPUT")"
  go build $GO_BUILD_ARG -o "$GO_OUTPUT" "$GO_PACKAGE"
}

# ==========================================================
#  主入口
# ==========================================================
case "${1:-}" in
  list)  list_env ;;
  reset) reset_env ;;
  build) # 非交互，直接编译
    [[ -f "$CACHE_FILE" ]] && {
      last=$(<"$CACHE_FILE")
      for i in "${!PREFIXES[@]}"; do
        [[ "${PREFIXES[i]}" == "$last" ]] && { set_toolchain "$i"; break; }
      done
    }
    do_go_build
    ;;
  "")
    interactive_select && {
      echo "${yellow}提示：如想变量在子进程也生效，请执行：${reset}"
      echo "  source $0"
      echo ""
      echo "${yellow}要直接编译 so，可接着执行：${reset}"
      echo "  $0 build"
    }
    ;;
  *)
    if [[ "$1" =~ ^[0-9]+$ ]] && (( $1 >= 1 && $1 <= ${#PREFIXES[@]} )); then
      set_toolchain "$(( $1-1 ))"
      echo "${PREFIXES[$(( $1-1 ))]}" > "$CACHE_FILE"
    else
      echo "${red}用法：$0 [list|reset|build|数字]${reset}" >&2
      exit 1
    fi
    ;;
esac