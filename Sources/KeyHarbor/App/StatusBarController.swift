import AppKit
import Combine

final class StatusBarController {
    private let statusItem: NSStatusItem
    private let appState: AppState
    private let onOpenSettings: () -> Void
    private let enabledItem = NSMenuItem()
    private var cancellables = Set<AnyCancellable>()

    init(appState: AppState, onOpenSettings: @escaping () -> Void) {
        self.appState = appState
        self.onOpenSettings = onOpenSettings
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        configureButton()
        configureMenu()
        observeState()
    }

    private func configureButton() {
        if let button = statusItem.button {
            button.toolTip = "快捷虾"
            button.title = "快捷虾"
            if let image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "快捷虾") {
                image.isTemplate = true
                button.image = image
                button.imagePosition = .imageLeading
            } else {
                button.title = "快捷虾"
            }
        }
    }

    private func configureMenu() {
        let menu = NSMenu()

        let settingsItem = NSMenuItem(
            title: "打开键盘设置",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        enabledItem.action = #selector(toggleHotkeys)
        enabledItem.target = self
        menu.addItem(enabledItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "退出快捷虾",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = NSApp
        menu.addItem(quitItem)

        statusItem.menu = menu
        updateEnabledItem()
    }

    private func observeState() {
        appState.$isHotkeysEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateEnabledItem()
            }
            .store(in: &cancellables)
    }

    private func updateEnabledItem() {
        enabledItem.title = appState.isHotkeysEnabled ? "暂停切换快捷键" : "启用切换快捷键"
    }

    @objc private func openSettings() {
        onOpenSettings()
    }

    @objc private func toggleHotkeys() {
        appState.setHotkeysEnabled(!appState.isHotkeysEnabled)
    }
}
