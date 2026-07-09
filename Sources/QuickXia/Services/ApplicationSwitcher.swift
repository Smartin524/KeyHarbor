import AppKit
import ApplicationServices

final class ApplicationSwitcher {
    private let activateRetryDelays: [TimeInterval] = [0.15, 0.45, 0.90, 1.50]
    private let focusRetryDelays: [TimeInterval] = [0.20, 0.55, 1.00, 1.70]

    func openOrActivate(_ binding: AppBinding) {
        let url = URL(fileURLWithPath: binding.appPath)
        guard FileManager.default.fileExists(atPath: url.path) else {
            NSSound.beep()
            return
        }

        if let runningApp = runningApplication(bundleIdentifier: binding.bundleIdentifier),
           runningApp.isActive {
            closeOrHide(runningApp)
            return
        }

        guard openApplication(at: url) else {
            NSSound.beep()
            return
        }

        if let runningApp = runningApplication(bundleIdentifier: binding.bundleIdentifier) {
            activate(runningApp)
        } else {
            retryActivate(bundleIdentifier: binding.bundleIdentifier)
        }
    }

    func activate(_ runningApp: NSRunningApplication) {
        runningApp.unhide()
        runningApp.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        retryFocusFrontWindow(of: runningApp)
    }

    private func openApplication(at url: URL) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [url.path]

        do {
            try process.run()
            return true
        } catch {
            return false
        }
    }

    private func retryActivate(bundleIdentifier: String) {
        for delay in activateRetryDelays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self,
                      let runningApp = self.runningApplication(bundleIdentifier: bundleIdentifier) else {
                    return
                }

                self.activate(runningApp)
            }
        }
    }

    private func retryFocusFrontWindow(of runningApp: NSRunningApplication) {
        guard AccessibilityPermission.isTrusted(promptIfNeeded: true) else {
            return
        }

        for delay in focusRetryDelays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak runningApp] in
                guard let self, let runningApp, !runningApp.isTerminated else {
                    return
                }

                self.focusFrontWindow(of: runningApp)
            }
        }
    }

    private func closeOrHide(_ runningApp: NSRunningApplication) {
        guard AccessibilityPermission.isTrusted(promptIfNeeded: true),
              closeFrontWindow(of: runningApp) else {
            runningApp.hide()
            return
        }
    }

    private func closeFrontWindow(of runningApp: NSRunningApplication) -> Bool {
        let appElement = AXUIElementCreateApplication(runningApp.processIdentifier)
        guard let window = preferredWindow(from: appElement),
              let closeButton = copyAttribute(kAXCloseButtonAttribute, from: window, as: AXUIElement.self) else {
            return false
        }

        return AXUIElementPerformAction(closeButton, kAXPressAction as CFString) == .success
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

    private func runningApplication(bundleIdentifier: String) -> NSRunningApplication? {
        NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleIdentifier)
            .first
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
