#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_BINARY="$ROOT_DIR/.build/ConfigStoreTests"

cd "$ROOT_DIR"
swiftc -warnings-as-errors -target "$(uname -m)-apple-macosx13.0" \
    Sources/KeyHarbor/Models/AppBinding.swift \
    Sources/KeyHarbor/Models/KeyboardKey.swift \
    Sources/KeyHarbor/Services/AccessibilityPermission.swift \
    Sources/KeyHarbor/Services/AppState.swift \
    Sources/KeyHarbor/Services/ApplicationSwitcher.swift \
    Sources/KeyHarbor/Services/ConfigStore.swift \
    Sources/KeyHarbor/Services/DesktopPresenter.swift \
    Sources/KeyHarbor/Services/HotKeyManager.swift \
    Sources/KeyHarbor/Services/LaunchAtLoginService.swift \
    Sources/KeyHarbor/Services/ModifierChordMonitor.swift \
    Tests/ConfigStoreTests.swift \
    -o "$TEST_BINARY"

"$TEST_BINARY"
