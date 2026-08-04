#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_BINARY="$ROOT_DIR/.build/ConfigStoreTests"

cd "$ROOT_DIR"
swiftc -warnings-as-errors -target "$(uname -m)-apple-macosx13.0" \
    Sources/keyharbor/Models/AppBinding.swift \
    Sources/keyharbor/Models/KeyboardKey.swift \
    Sources/keyharbor/Services/AccessibilityPermission.swift \
    Sources/keyharbor/Services/AppState.swift \
    Sources/keyharbor/Services/ApplicationSwitcher.swift \
    Sources/keyharbor/Services/ConfigStore.swift \
    Sources/keyharbor/Services/DesktopPresenter.swift \
    Sources/keyharbor/Services/HotKeyManager.swift \
    Sources/keyharbor/Services/LaunchAtLoginService.swift \
    Tests/ConfigStoreTests.swift \
    -o "$TEST_BINARY"

"$TEST_BINARY"
