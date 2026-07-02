import Carbon
import Foundation

struct AppBinding: Identifiable, Codable, Equatable {
    var id: UUID
    var displayName: String
    var bundleIdentifier: String
    var appPath: String
    var keyCode: UInt32
    var modifiers: UInt32
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        displayName: String,
        bundleIdentifier: String,
        appPath: String,
        keyCode: UInt32,
        modifiers: UInt32 = UInt32(optionKey),
        isEnabled: Bool = true
    ) {
        self.id = id
        self.displayName = displayName
        self.bundleIdentifier = bundleIdentifier
        self.appPath = appPath
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.isEnabled = isEnabled
    }
}

struct AppConfig: Codable {
    var version: Int
    var hotkeysEnabled: Bool
    var bindings: [AppBinding]
}

extension AppConfig {
    static let currentVersion = 1

    static func defaults() -> AppConfig {
        AppConfig(
            version: currentVersion,
            hotkeysEnabled: true,
            bindings: [
                AppBinding(
                    displayName: "WeChat",
                    bundleIdentifier: "com.tencent.xinWeChat",
                    appPath: "/Applications/WeChat.app",
                    keyCode: KeyCodes.w
                ),
                AppBinding(
                    displayName: "Codex",
                    bundleIdentifier: "com.openai.codex",
                    appPath: "/Applications/Codex.app",
                    keyCode: KeyCodes.c
                )
            ]
        )
    }
}
