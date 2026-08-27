#!/usr/bin/env bash
set -euo pipefail

# Builds ca.psiphon.aar from the psiphon-tunnel-core fork and drops it where the
# :psiphon gradle module expects it.
#
# The fork vendors its dependencies and pins golang.org/x/* deliberately, so the
# golang.org/x/mobile requirement that gomobile needs is added to the checkout at
# build time instead of being committed to the fork.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$here/.." && pwd)"

psiphon_dir="${PSIPHON_DIR:-$(cd "$repo/.." && pwd)/psiphon-tunnel-core}"
gomobile_version="${GOMOBILE_VERSION:-v0.0.0-20260821190718-4776eadac327}"
android_api="${PSIPHON_ANDROID_API:-35}"
targets="${PSIPHON_TARGETS:-android/arm,android/arm64,android/386,android/amd64}"
destination="$repo/android/psiphon/ca.psiphon.aar"

if [ ! -d "$psiphon_dir" ]; then
  echo "psiphon-tunnel-core not found at $psiphon_dir" >&2
  echo "clone https://github.com/CluvexStudio/psiphon-tunnel-core (branch shirokhorshid) there, or set PSIPHON_DIR" >&2
  exit 1
fi

if [ -z "${ANDROID_NDK_HOME:-}" ] && [ -z "${ANDROID_NDK_ROOT:-}" ]; then
  echo "set ANDROID_NDK_HOME so gomobile can find the ndk" >&2
  exit 1
fi

# make.bash compiles PsiphonTunnel.java against android.jar, so it needs the sdk
# and a platform version. Neither is exported by default on CI runners.
android_home="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [ -z "$android_home" ] || [ ! -d "$android_home/platforms" ]; then
  echo "set ANDROID_HOME to an android sdk that has a platform installed" >&2
  exit 1
fi
export ANDROID_HOME="$android_home"

platform="${ANDROID_PLATFORM_VERSION:-}"
if [ -z "$platform" ]; then
  for candidate in $(ls "$android_home/platforms" | sed -n 's/^android-//p' | sort -V); do
    if [ -f "$android_home/platforms/android-$candidate/android.jar" ]; then
      platform="$candidate"
    fi
  done
fi
if [ -z "$platform" ] || [ ! -f "$android_home/platforms/android-$platform/android.jar" ]; then
  echo "no usable android.jar under $android_home/platforms" >&2
  ls "$android_home/platforms" >&2 || true
  exit 1
fi
export ANDROID_PLATFORM_VERSION="$platform"

echo "[psiphon] fork:     $psiphon_dir"
echo "[psiphon] gomobile: $gomobile_version"
echo "[psiphon] api:      $android_api"
echo "[psiphon] platform: android-$platform"
echo "[psiphon] targets:  $targets"

go install "golang.org/x/mobile/cmd/gomobile@$gomobile_version"
go install "golang.org/x/mobile/cmd/gobind@$gomobile_version"
export PATH="$(go env GOPATH)/bin:$PATH"

cd "$psiphon_dir"

# The tool directive below rewrites go.mod, so keep a copy and put it back on the
# way out. A local checkout of the fork should not be left dirty by a build.
manifests="$(mktemp -d)"
cp go.mod go.sum "$manifests/"

cleanup() {
  cp "$manifests/go.mod" "$psiphon_dir/go.mod"
  cp "$manifests/go.sum" "$psiphon_dir/go.sum"
  rm -rf "$manifests" "${inspect:-}"
}
trap cleanup EXIT

# The fork ships a vendor directory, which go would otherwise prefer, and
# golang.org/x/mobile is deliberately not vendored there. Resolving from the
# module cache keeps the fork's vendored tree untouched.
export GOFLAGS=-mod=mod

# gomobile refuses to run unless the module records x/mobile as a tool
# dependency, because the code it generates imports golang.org/x/mobile/bind.
go get -tool "golang.org/x/mobile/cmd/gobind@$gomobile_version"

gomobile init

cd MobileLibrary/Android
PSIPHON_TARGETS="$targets" PSIPHON_ANDROID_API="$android_api" ./make.bash

mkdir -p "$(dirname "$destination")"
cp ca.psiphon.aar "$destination"

echo "[psiphon] wrote $destination"

if command -v readelf >/dev/null 2>&1; then
  inspect="$(mktemp -d)"
  unzip -qo "$destination" -d "$inspect" 'jni/*'
  for library in "$inspect"/jni/*/libgojni.so; do
    alignments="$(readelf -lW "$library" | awk '$1=="LOAD"{print $NF}' | sort -u)"
    if [ "$alignments" != "0x4000" ]; then
      echo "::error::$(basename "$(dirname "$library")")/libgojni.so is not 16 KB aligned: $alignments" >&2
      exit 1
    fi
  done
  echo "[psiphon] every libgojni.so is 16 KB aligned"
fi
