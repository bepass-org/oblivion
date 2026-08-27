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

echo "[psiphon] fork:     $psiphon_dir"
echo "[psiphon] gomobile: $gomobile_version"
echo "[psiphon] api:      $android_api"
echo "[psiphon] targets:  $targets"

go install "golang.org/x/mobile/cmd/gomobile@$gomobile_version"
go install "golang.org/x/mobile/cmd/gobind@$gomobile_version"
export PATH="$(go env GOPATH)/bin:$PATH"

cd "$psiphon_dir"

# gomobile generates code that imports golang.org/x/mobile/bind, so the module
# needs it in its build list and, because the fork vendors, in vendor/ as well.
GOFLAGS=-mod=mod go get "golang.org/x/mobile/bind@$gomobile_version"
GOFLAGS=-mod=mod go mod vendor

gomobile init

# Android 15 and later require every shared library to tolerate a 16 KB page
# size. gomobile forwards CGO_LDFLAGS to the ndk linker.
export CGO_LDFLAGS="-Wl,-z,max-page-size=16384,-z,common-page-size=16384"

cd MobileLibrary/Android
PSIPHON_TARGETS="$targets" PSIPHON_ANDROID_API="$android_api" ./make.bash

mkdir -p "$(dirname "$destination")"
cp ca.psiphon.aar "$destination"

echo "[psiphon] wrote $destination"

if command -v readelf >/dev/null 2>&1; then
  workdir="$(mktemp -d)"
  trap 'rm -rf "$workdir"' EXIT
  unzip -qo "$destination" -d "$workdir" 'jni/*'
  for library in "$workdir"/jni/*/libgojni.so; do
    alignments="$(readelf -lW "$library" | awk '$1=="LOAD"{print $NF}' | sort -u)"
    if [ "$alignments" != "0x4000" ]; then
      echo "::error::$(basename "$(dirname "$library")")/libgojni.so is not 16 KB aligned: $alignments" >&2
      exit 1
    fi
  done
  echo "[psiphon] every libgojni.so is 16 KB aligned"
fi
