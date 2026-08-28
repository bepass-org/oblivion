#!/usr/bin/env bash
set -euo pipefail

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

android_home="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [ -z "$android_home" ] || [ ! -d "$android_home/platforms" ]; then
  echo "set ANDROID_HOME to an android sdk that has a platform installed" >&2
  exit 1
fi
export ANDROID_HOME="$android_home"

platform="${ANDROID_PLATFORM_VERSION:-}"
if [ -z "$platform" ]; then
  for candidate in $(ls "$android_home/platforms" |
    sed -n 's/^android-\([0-9]\{1,\}\)$/\1/p' | sort -n); do
    if [ -f "$android_home/platforms/android-$candidate/android.jar" ]; then
      platform="$candidate"
    fi
  done
fi
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

manifests="$(mktemp -d)"
cp go.mod go.sum "$manifests/"

cleanup() {
  cp "$manifests/go.mod" "$psiphon_dir/go.mod"
  cp "$manifests/go.sum" "$psiphon_dir/go.sum"
  rm -rf "$manifests" "${inspect:-}"
}
trap cleanup EXIT

export GOFLAGS=-mod=mod

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
