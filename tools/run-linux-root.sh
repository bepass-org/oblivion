#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-release}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE_DIR="$PROJECT_DIR/build/linux/x64/$MODE/bundle"
BINARY="$BUNDLE_DIR/oblivion"

if [[ ! -x "$BINARY" ]]; then
    echo "bundle not found at $BINARY" >&2
    echo "build it first: flutter build linux --$MODE" >&2
    exit 1
fi

if [[ "$(id -u)" -eq 0 ]]; then
    echo "run this script as your normal user, it elevates on its own" >&2
    exit 1
fi

CALLER_UID="$(id -u)"
SESSION_TYPE="${XDG_SESSION_TYPE:-x11}"
GRANTED_XHOST=0

cleanup() {
    if [[ "$GRANTED_XHOST" -eq 1 ]]; then
        xhost -si:localuser:root >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

FORWARD=(
    "HOME=/root"
    "XDG_SESSION_TYPE=$SESSION_TYPE"
)

if [[ -n "${OBLIVION_BYPASS_UID:-}" ]]; then
    FORWARD+=("OBLIVION_BYPASS_UID=$OBLIVION_BYPASS_UID")
fi

if [[ -n "${DISPLAY:-}" ]]; then
    FORWARD+=("DISPLAY=$DISPLAY")
    if [[ -n "${XAUTHORITY:-}" ]]; then
        FORWARD+=("XAUTHORITY=$XAUTHORITY")
    fi
    if command -v xhost >/dev/null 2>&1; then
        if xhost +si:localuser:root >/dev/null 2>&1; then
            GRANTED_XHOST=1
        fi
    fi
fi

if [[ "$SESSION_TYPE" == "wayland" && -n "${WAYLAND_DISPLAY:-}" ]]; then
    FORWARD+=("WAYLAND_DISPLAY=$WAYLAND_DISPLAY")
    FORWARD+=("XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$CALLER_UID}")
fi

echo "launching $BINARY as root"
echo "session=$SESSION_TYPE display=${DISPLAY:-none}"

cd "$BUNDLE_DIR"
sudo env "${FORWARD[@]}" ./oblivion "${@:2}"
