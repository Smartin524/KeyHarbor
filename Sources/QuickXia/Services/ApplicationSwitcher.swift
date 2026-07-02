import AppKit
import ApplicationServices

final class ApplicationSwitcher {
    private let focusRetryDelays: [TimeInterval] = [0.08, 0.24, 0.50]

    func openOrActivate(_ binding: AppBinding) {
        if let runningApp = NSRunningApplication
            .runningApplications(withBundleIdentifier: binding.bundleIdentifier)
            .first {
            activate(runningApp)
            return
        }

        let url = URL(fileURLWithPath: binding.appPath)
        guard FileManager.default.fileExists(atPath: url.path) else {
            NSSound.beep()
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { [weak self] runningApp, error in
            if error != nil {
                NSSound.beep()
                return
            }

            if let runningApp {
                self?.activate(runningApp)
            }
        }
    }

    func activate(_ runningApp: NSRunningApplication) {
        runningApp.unhide()
        runningApp.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])

        guard AccessibilityPermission.isTrusted(promptIfNeeded: true) else { return }

        for delay in focusRetryDelays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak runningApp] in
                guard let self, let runningApp, !runningApp.isTerminated else { return }
                self.focusFrontWindow(of: runningApp)
            }
        }
    }

    private func focusFrontWindow(of runningApp: NSRunningApplication) {
        let appElement = AXUIElementCreateApplication(runningApp.processIdentifier)
        guard let window = preferredWindow(from: appElement) else { return }

        unminimize(window)
        AXUIElementSetAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, window)
        AXUIElementSetAttributeValue(window, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        AXUIElementPerformAction(window, kAXRaiseAction as CFString)
    }

    private func preferredWindow(from appElement: AXUIElement) -> AXUIElement? {
        if let focusedWindow = copyAttribute(kAXFocusedWindowAttribute, from: appElement, as: AXUIElement.self) {
            return focusedWindow
        }

        if let mainWindow = copyAttribute(kAXMainWindowAttribute, from: appElement, as: AXUIElement.self) {
            return mainWindow
        }

        let windows = copyAttribute(kAXWindowsAttribute, from: appElement, as: [AXUIElement].self) ?? []
        return windows.first { !isMinimized($0) } ?? windows.first
    }

    private func unminimize(_ window: AXUIElement) {
        guard isMinimized(window) else { return }
        AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
    }

    private func isMinimized(_ window: AXUIElement) -> Bool {
        copyAttribute(kAXMinimizedAttribute, from: window, as: Bool.self) ?? false
    }

    private func copyAttribute<T>(_ attribute: String, from element: AXUIElement, as type: T.Type) -> T? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)

        guard error == .success, let value else {
            return nil
        }

        return value as? T
    }
}
