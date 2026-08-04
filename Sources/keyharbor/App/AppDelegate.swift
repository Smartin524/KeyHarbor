import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appState = AppState()
    private var statusBarController: StatusBarController?
    private var settingsWindowController: SettingsWindowController?
    private var hasStarted = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        startIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState.unregisterHotkeys()
    }

    func startIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true

        statusBarController = StatusBarController(appState: appState) { [weak self] in
            self?.showSettingsWindow()
        }
        settingsWindowController = SettingsWindowController(appState: appState)
        appState.onShowPanel = { [weak self] in
            self?.toggleSettingsWindow()
        }
        appState.enableLaunchAtLoginIfNeeded()
        appState.registerHotkeys()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.showSettingsWindow()
        }
    }

    private func showSettingsWindow() {
        settingsWindowController?.showWindow()
    }

    private func toggleSettingsWindow() {
        settingsWindowController?.toggleWindow()
    }
}
