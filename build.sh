export GOARCH=arm64
export GOOS=android
export CGO_ENABLED=1

export LLVMCONFIG=/root/command-line-tools/sdk/default/openharmony/native/llvm/bin/llvm-config
export CGO_CFLAGS="-g -O2 `$LLVMCONFIG --cflags` --target=aarch64-linux-ohos --sysroot=/root/command-line-tools/sdk/default/openharmony/native/sysroot"
export CGO_LDFLAGS="--target=aarch64-linux-ohos -fuse-ld=lld"

export CC="/root/command-line-tools/sdk/default/openharmony/native/llvm/bin/clang"
export CXX="/root/command-line-tools/sdk/default/openharmony/native/llvm/bin/clang++"
export AR="/root/command-line-tools/sdk/default/openharmony/native/llvm/bin/llvm-ar"
export LD="/root/command-line-tools/sdk/default/openharmony/native/llvm/bin/lld"

#go build -buildmode=c-shared -v -x -o ./build/arm64-v8a/libhamary.so ./cgo

go build -x -buildmode=c-shared -o ./build/arm64-v8a/libhamary.so -x ./cgo