import AppKit
import Foundation

final class DesktopPresenter {
    private let finderBundleIdentifier = "com.apple.finder"
    private let finderURL = URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")
    private let applicationSwitcher: ApplicationSwitcher
    private var lastFocusedApplication: NSRunningApplication?
    private var isShowingDesktop = false

    init(applicationSwitcher: ApplicationSwitcher = ApplicationSwitcher()) {
        self.applicationSwitcher = applicationSwitcher
    }

    func toggleDesktop() {
        if shouldRestorePreviousApplication {
            restorePreviousApplication()
            return
        }

        showDesktop()
    }

    private var shouldRestorePreviousApplication: Bool {
        guard isShowingDesktop,
              let lastFocusedApplication,
              !lastFocusedApplication.isTerminated else {
            return false
        }

        return NSWorkspace.shared.frontmostApplication?.bundleIdentifier == finderBundleIdentifier
    }

    private func restorePreviousApplication() {
        guard let app = lastFocusedApplication, !app.isTerminated else {
            isShowingDesktop = false
            lastFocusedApplication = nil
            self.showDesktop()
            return
        }

        isShowingDesktop = false
        lastFocusedApplication = nil
        applicationSwitcher.activate(app)
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
        for app in NSWorkspace.shared.runningApplications where shouldHide(app) {
            app.hide()
        }
    }

    private func shouldHide(_ app: NSRunningApplication) -> Bool {
        guard app.activationPolicy == .regular else { return false }
        return app.bundleIdentifier != finderBundleIdentifier
    }

    private func showDesktop() {
        lastFocusedApplication = frontmostRestorableApplication()
        isShowingDesktop = true
        hideVisibleApplications()
        activateFinder()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.hideVisibleApplications()
            self?.activateFinder()
        }
    }

    private func frontmostRestorableApplication() -> NSRunningApplication? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              shouldHide(app) else {
            return nil
        }

        return app
    }
}
