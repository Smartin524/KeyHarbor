import ApplicationServices
import Foundation

enum AccessibilityPermission {
    private static var hasRequestedPermission = false

    static func isTrusted(promptIfNeeded: Bool) -> Bool {
        if AXIsProcessTrusted() {
            return true
        }

        guard promptIfNeeded, !hasRequestedPermission else {
            return false
        }

        hasRequestedPermission = true
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
