import AppKit
import Combine
import Carbon
import Foundation

final class AppState: ObservableObject {
    @Published private(set) var bindings: [AppBinding]
    @Published private(set) var isHotkeysEnabled: Bool
    @Published var selectedKeyCode: UInt32?
    @Published var statusMessage: String?
    var onShowPanel: (() -> Void)?

    private let store: ConfigStore
    private let switcher: ApplicationSwitcher
    private let desktopPresenter: DesktopPresenter
    private let launchAtLoginService: LaunchAtLoginService
    private let panelShortcut = HotKeyShortcut(
        keyCode: KeyCodes.returnKey,
        modifiers: UInt32(optionKey) | UInt32(cmdKey)
    )
    private let desktopShortcut = HotKeyShortcut(keyCode: KeyCodes.space, modifiers: UInt32(optionKey))
    private lazy var hotKeyManager = HotKeyManager { [weak self] action in
        DispatchQueue.main.async {
            self?.handleHotKey(action)
        }
    }

    init(
        store: ConfigStore = ConfigStore(),
        switcher: ApplicationSwitcher = ApplicationSwitcher(),
        desktopPresenter: DesktopPresenter? = nil,
        launchAtLoginService: LaunchAtLoginService = LaunchAtLoginService()
    ) {
        self.store = store
        self.switcher = switcher
        self.desktopPresenter = desktopPresenter ?? DesktopPresenter(applicationSwitcher: switcher)
        self.launchAtLoginService = launchAtLoginService
        let config = store.load()
        self.bindings = config.bindings
        self.isHotkeysEnabled = config.hotkeysEnabled
        self.selectedKeyCode = KeyCodes.w
    }

    func registerHotkeys() {
        hotKeyManager.register(
            bindings: bindings,
            enabled: isHotkeysEnabled,
            panelShortcut: panelShortcut,
            desktopShortcut: desktopShortcut
        )
    }

    func unregisterHotkeys() {
        hotKeyManager.unregisterAll()
    }

    func setHotkeysEnabled(_ enabled: Bool) {
        guard enabled != isHotkeysEnabled else { return }
        _ = commit(
            bindings: bindings,
            hotkeysEnabled: enabled,
            successMessage: enabled ? "切换快捷键已启用" : "切换快捷键已暂停"
        )
    }

    func enableLaunchAtLoginIfNeeded() {
        guard !launchAtLoginService.isEnabled else { return }

        do {
            try launchAtLoginService.setEnabled(true)
            if launchAtLoginService.needsApproval {
                statusMessage = "请在系统设置中允许开机自启"
            }
        } catch {
            statusMessage = "开机自启设置失败"
        }
    }

    func binding(for keyCode: UInt32) -> AppBinding? {
        guard !isDesktopShortcutKey(keyCode) else { return nil }
        return bindings.first { $0.keyCode == keyCode }
    }

    func select(keyCode: UInt32?) {
        selectedKeyCode = keyCode
        statusMessage = nil
    }

    func saveBinding(_ binding: AppBinding) -> Bool {
        if isDesktopShortcut(keyCode: binding.keyCode, modifiers: binding.modifiers) {
            statusMessage = "⌥Space 已用于显示/返回桌面"
            return false
        }

        if hasDuplicateShortcut(keyCode: binding.keyCode, modifiers: binding.modifiers, excluding: binding.id) {
            statusMessage = "这个快捷键已经被其他应用使用了"
            return false
        }

        var updatedBindings = bindings
        if let index = updatedBindings.firstIndex(where: { $0.id == binding.id }) {
            updatedBindings[index] = binding
        } else if let index = updatedBindings.firstIndex(where: { $0.keyCode == binding.keyCode }) {
            updatedBindings[index] = binding
        } else {
            updatedBindings.append(binding)
        }

        return commit(
            bindings: updatedBindings,
            hotkeysEnabled: isHotkeysEnabled,
            successMessage: "已保存绑定"
        )
    }

    func bindApplication(at url: URL, to keyCode: UInt32) {
        guard !isDesktopShortcutKey(keyCode) else {
            statusMessage = "⌥Space 已用于显示/返回桌面"
            return
        }

        guard let bundle = Bundle(url: url),
              let bundleIdentifier = bundle.bundleIdentifier else {
            statusMessage = "这个 App 无法读取 Bundle ID"
            return
        }

        let displayName = (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? url.deletingPathExtension().lastPathComponent
        let existingID = binding(for: keyCode)?.id ?? UUID()
        let binding = AppBinding(
            id: existingID,
            displayName: displayName,
            bundleIdentifier: bundleIdentifier,
            appPath: url.path,
            keyCode: keyCode,
            modifiers: UInt32(optionKey)
        )

        _ = saveBinding(binding)
    }

    func clearBinding(for keyCode: UInt32) {
        let updatedBindings = bindings.filter { $0.keyCode != keyCode }
        guard updatedBindings.count != bindings.count else {
            statusMessage = "当前按键没有绑定"
            return
        }

        _ = commit(
            bindings: updatedBindings,
            hotkeysEnabled: isHotkeysEnabled,
            successMessage: "已清除绑定"
        )
    }

    func isDesktopShortcutKey(_ keyCode: UInt32?) -> Bool {
        keyCode == desktopShortcut.keyCode
    }

    private func isDesktopShortcut(keyCode: UInt32, modifiers: UInt32) -> Bool {
        keyCode == desktopShortcut.keyCode && modifiers == desktopShortcut.modifiers
    }

    private func hasDuplicateShortcut(keyCode: UInt32, modifiers: UInt32, excluding id: UUID) -> Bool {
        bindings.contains { binding in
            binding.id != id &&
            binding.keyCode == keyCode &&
            binding.modifiers == modifiers
        }
    }

    private func handleHotKey(_ action: HotKeyAction) {
        switch action {
        case .toggleDesktop:
            guard isHotkeysEnabled else { return }
            desktopPresenter.toggleDesktop()
        case .showPanel:
            onShowPanel?()
        case .appBinding(let bindingID):
            openBinding(bindingID)
        }
    }

    private func openBinding(_ bindingID: UUID) {
        guard isHotkeysEnabled,
              let binding = bindings.first(where: { $0.id == bindingID }) else {
            return
        }
        switcher.openOrActivate(binding)
    }

    @discardableResult
    private func commit(
        bindings newBindings: [AppBinding],
        hotkeysEnabled: Bool,
        successMessage: String?
    ) -> Bool {
        let config = AppConfig(
            version: AppConfig.currentVersion,
            hotkeysEnabled: hotkeysEnabled,
            bindings: newBindings
        )

        do {
            try store.save(config)
            bindings = newBindings
            isHotkeysEnabled = hotkeysEnabled
            statusMessage = successMessage
            registerHotkeys()
            return true
        } catch {
            statusMessage = "保存配置失败：\(error.localizedDescription)"
            return false
        }
    }
}
