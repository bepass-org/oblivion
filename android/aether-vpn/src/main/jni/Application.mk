APP_OPTIM := release
APP_PLATFORM := android-24
APP_ABI := armeabi-v7a arm64-v8a x86_64
APP_CFLAGS := -O3 -DPKGNAME=org/bepass/oblivion/vpn -DCLSNAME=TProxyService
APP_LDFLAGS := -Wl,--build-id=none -Wl,--hash-style=gnu
APP_SUPPORT_FLEXIBLE_PAGE_SIZES := true
NDK_TOOLCHAIN_VERSION := clang
