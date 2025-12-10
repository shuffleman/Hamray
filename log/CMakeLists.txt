cmake_minimum_required(VERSION 3.15)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

project(log)

include_directories(/home/groot/ohos-sdk-41/linux/native/sysroot/usr/include)
link_directories(/home/groot/ohos-sdk-41/linux/native/sysroot/usr/lib/aarch64-linux-ohos)

add_library(log SHARED
    ${CMAKE_SOURCE_DIR}/log.h
    ${CMAKE_SOURCE_DIR}/log.c
)

target_link_libraries(log PUBLIC libace_napi.z.so libhilog_ndk.z.so)