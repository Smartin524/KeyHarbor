#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="快捷虾"
SOURCE_APP="$ROOT_DIR/dist/$APP_NAME.app"
TARGET_APP="/Applications/$APP_NAME.app"

bash "$ROOT_DIR/Scripts/package_app.sh" >/dev/null

if pgrep -x keyharbor >/dev/null 2>&1; then
    pkill -x keyharbor || true
fi

rm -rf "$TARGET_APP"
cp -R "$SOURCE_APP" "$TARGET_APP"

if command -v codesign >/dev/null 2>&1; then
    codesign --force --deep --sign - "$TARGET_APP" >/dev/null
fi

/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f "$TARGET_APP" >/dev/null 2>&1 || true

open "$TARGET_APP"
echo "$TARGET_APP"
