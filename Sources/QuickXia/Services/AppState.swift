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
    private let panelChord = ModifierChord(flags: [.option, .command])
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
        self.bindings = config.bindings.map(Self.enabledBinding)
        self.isHotkeysEnabled = true
        self.selectedKeyCode = KeyCodes.w
    }

    func registerHotkeys() {
        hotKeyManager.register(
            bindings: bindings,
            enabled: isHotkeysEnabled,
            panelChord: panelChord,
            desktopShortcut: desktopShortcut
        )
    }

    func unregisterHotkeys() {
        hotKeyManager.unregisterAll()
    }

    func setHotkeysEnabled(_ enabled: Bool) {
        isHotkeysEnabled = enabled
        persistAndRegister()
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

        if let index = bindings.firstIndex(where: { $0.id == binding.id }) {
            bindings[index] = binding
        } else if let index = bindings.firstIndex(where: { $0.keyCode == binding.keyCode }) {
            bindings[index] = binding
        } else {
            bindings.append(binding)
        }

        statusMessage = "已保存绑定"
        persistAndRegister()
        return true
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
            modifiers: UInt32(optionKey),
            isEnabled: true
        )

        _ = saveBinding(binding)
    }

    func clearBinding(for keyCode: UInt32) {
        bindings.removeAll { $0.keyCode == keyCode }
        statusMessage = "已清除绑定"
        persistAndRegister()
    }

    func appExists(for binding: AppBinding) -> Bool {
        FileManager.default.fileExists(atPath: binding.appPath)
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

    private static func enabledBinding(_ binding: AppBinding) -> AppBinding {
        var binding = binding
        binding.isEnabled = true
        return binding
    }

    private func handleHotKey(_ action: HotKeyAction) {
        switch action {
        case .toggleDesktop:
            desktopPresenter.toggleDesktop()
        case .showPanel:
            onShowPanel?()
        case .appBinding(let bindingID):
            openBinding(bindingID)
        }
    }

    private func openBinding(_ bindingID: UUID) {
        guard isHotkeysEnabled,
              let binding = bindings.first(where: { $0.id == bindingID && $0.isEnabled }) else {
            return
        }
        switcher.openOrActivate(binding)
    }

    private func persistAndRegister() {
        let config = AppConfig(
            version: AppConfig.currentVersion,
            hotkeysEnabled: isHotkeysEnabled,
            bindings: bindings
        )

        do {
            try store.save(config)
            registerHotkeys()
        } catch {
            statusMessage = "保存配置失败：\(error.localizedDescription)"
        }
    }
}
