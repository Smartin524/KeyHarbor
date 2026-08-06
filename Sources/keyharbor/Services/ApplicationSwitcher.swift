import AppKit
import ApplicationServices

final class ApplicationSwitcher {
    private let focusRetryDelays: [TimeInterval] = [0.08, 0.24, 0.50]
    private var requestGeneration = 0
    private var pendingFocusWorkItems: [DispatchWorkItem] = []

    deinit {
        cancelPendingFocusWorkItems()
    }

    func openOrActivate(_ binding: AppBinding) {
        let generation = beginRequest()
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

        openApplication(
            at: url,
            bundleIdentifier: binding.bundleIdentifier,
            generation: generation
        )
    }

    func activate(_ runningApp: NSRunningApplication) {
        let generation = beginRequest()
        activate(runningApp, generation: generation)
    }

    private func activate(_ runningApp: NSRunningApplication, generation: Int) {
        guard isCurrentRequest(generation), !runningApp.isTerminated else { return }
        runningApp.unhide()
        runningApp.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        scheduleFocusRetries(for: runningApp, generation: generation)
    }

    private func openApplication(
        at url: URL,
        bundleIdentifier: String,
        generation: Int
    ) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { [weak self] app, error in
            DispatchQueue.main.async {
                guard let self, self.isCurrentRequest(generation) else { return }

                guard error == nil,
                      let runningApp = app ?? self.runningApplication(bundleIdentifier: bundleIdentifier) else {
                    NSSound.beep()
                    return
                }

                self.activate(runningApp, generation: generation)
            }
        }
    }

    private func scheduleFocusRetries(for runningApp: NSRunningApplication, generation: Int) {
        guard AccessibilityPermission.isTrusted else {
            return
        }

        for delay in focusRetryDelays {
            let workItem = DispatchWorkItem { [weak self, weak runningApp] in
                guard let self,
                      let runningApp,
                      self.isCurrentRequest(generation),
                      !runningApp.isTerminated,
                      runningApp.isActive else {
                    return
                }

                self.focusFrontWindow(of: runningApp)
            }
            pendingFocusWorkItems.append(workItem)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }

    private func beginRequest() -> Int {
        cancelPendingFocusWorkItems()
        requestGeneration &+= 1
        return requestGeneration
    }

    private func isCurrentRequest(_ generation: Int) -> Bool {
        generation == requestGeneration
    }

    private func cancelPendingFocusWorkItems() {
        pendingFocusWorkItems.forEach { $0.cancel() }
        pendingFocusWorkItems.removeAll()
    }

    private func closeOrHide(_ runningApp: NSRunningApplication) {
        guard AccessibilityPermission.isTrusted,
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
