import AppKit
import Foundation

final class DesktopPresenter {
    private let finderBundleIdentifier = "com.apple.finder"
    private let finderURL = URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")
    private let rapidToggleInterval: TimeInterval = 0.35
    private let applicationSwitcher: ApplicationSwitcher
    private var lastFocusedApplication: NSRunningApplication?
    private var hiddenApplications: [NSRunningApplication] = []
    private var pendingShowDesktopWorkItem: DispatchWorkItem?
    private var desktopRequestedAt: Date?
    private var isShowingDesktop = false

    init(applicationSwitcher: ApplicationSwitcher = ApplicationSwitcher()) {
        self.applicationSwitcher = applicationSwitcher
    }

    deinit {
        pendingShowDesktopWorkItem?.cancel()
    }

    func toggleDesktop() {
        if shouldRestorePreviousApplication {
            restorePreviousApplication()
            return
        }

        showDesktop()
    }

    private var shouldRestorePreviousApplication: Bool {
        guard isShowingDesktop else { return false }

        if NSWorkspace.shared.frontmostApplication?.bundleIdentifier == finderBundleIdentifier {
            return true
        }

        guard restoreTarget != nil, let desktopRequestedAt else { return false }
        return Date().timeIntervalSince(desktopRequestedAt) <= rapidToggleInterval
    }

    private func restorePreviousApplication() {
        pendingShowDesktopWorkItem?.cancel()
        let app = restoreTarget
        restoreHiddenApplications()
        resetDesktopState()
        if let app {
            applicationSwitcher.activate(app)
        }
    }

    private var restoreTarget: NSRunningApplication? {
        guard let lastFocusedApplication, !lastFocusedApplication.isTerminated else { return nil }
        return lastFocusedApplication
    }

    private func activateFinder() {
        if let finder = NSRunningApplication
            .runningApplications(withBundleIdentifier: finderBundleIdentifier)
            .first {
            finder.unhide()
            finder.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: finderURL, configuration: configuration) { _, error in
            if error != nil {
                NSSound.beep()
            }
        }
    }

    private func hideVisibleApplications() {
        let visibleApplications = NSWorkspace.shared.runningApplications.filter {
            shouldHide($0) && !$0.isHidden
        }

        for app in visibleApplications {
            rememberHiddenApplication(app)
            app.hide()
        }
    }

    private func rememberHiddenApplication(_ app: NSRunningApplication) {
        guard !hiddenApplications.contains(where: { $0.processIdentifier == app.processIdentifier }) else {
            return
        }
        hiddenApplications.append(app)
    }

    private func restoreHiddenApplications() {
        for app in hiddenApplications where !app.isTerminated {
            app.unhide()
        }
    }

    private func shouldHide(_ app: NSRunningApplication) -> Bool {
        guard app.activationPolicy == .regular else { return false }
        return app.bundleIdentifier != finderBundleIdentifier
    }

    private func showDesktop() {
        pendingShowDesktopWorkItem?.cancel()
        if !isShowingDesktop {
            hiddenApplications.removeAll()
        }

        lastFocusedApplication = frontmostRestorableApplication()
        isShowingDesktop = true
        desktopRequestedAt = Date()
        hideVisibleApplications()
        activateFinder()

        let workItem = DispatchWorkItem { [weak self] in
            guard self?.isShowingDesktop == true else { return }
            self?.hideVisibleApplications()
            self?.activateFinder()
        }
        pendingShowDesktopWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: workItem)
    }

    private func frontmostRestorableApplication() -> NSRunningApplication? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              shouldHide(app) else {
            return nil
        }

        return app
    }

    private func resetDesktopState() {
        pendingShowDesktopWorkItem?.cancel()
        pendingShowDesktopWorkItem = nil
        desktopRequestedAt = nil
        lastFocusedApplication = nil
        hiddenApplications.removeAll()
        isShowingDesktop = false
    }
}
