import Carbon
import Foundation

struct AppBinding: Identifiable, Codable, Equatable {
    var id: UUID
    var displayName: String
    var bundleIdentifier: String
    var appPath: String
    var keyCode: UInt32
    var modifiers: UInt32

    init(
        id: UUID = UUID(),
        displayName: String,
        bundleIdentifier: String,
        appPath: String,
        keyCode: UInt32,
        modifiers: UInt32 = UInt32(optionKey)
    ) {
        self.id = id
        self.displayName = displayName
        self.bundleIdentifier = bundleIdentifier
        self.appPath = appPath
        self.keyCode = keyCode
        self.modifiers = modifiers
    }
}

struct AppConfig: Codable, Equatable {
    var version: Int
    var hotkeysEnabled: Bool
    var bindings: [AppBinding]
}

extension AppConfig {
    static let currentVersion = 2

    private static var defaultBindings: [AppBinding] {
        [
            AppBinding(
                displayName: "WeChat",
                bundleIdentifier: "com.tencent.xinWeChat",
                appPath: "/Applications/WeChat.app",
                keyCode: KeyCodes.w
            ),
            AppBinding(
                displayName: "ChatGPT",
                bundleIdentifier: "com.openai.codex",
                appPath: "/Applications/ChatGPT.app",
                keyCode: KeyCodes.c
            ),
            AppBinding(
                displayName: "Mail",
                bundleIdentifier: "com.apple.mail",
                appPath: "/System/Applications/Mail.app",
                keyCode: KeyCodes.e
            ),
            AppBinding(
                displayName: "Music",
                bundleIdentifier: "com.apple.Music",
                appPath: "/System/Applications/Music.app",
                keyCode: KeyCodes.m
            ),
            AppBinding(
                displayName: "Google Chrome",
                bundleIdentifier: "com.google.Chrome",
                appPath: "/Applications/Google Chrome.app",
                keyCode: KeyCodes.b
            )
        ]
    }

    static func defaults() -> AppConfig {
        AppConfig(
            version: currentVersion,
            hotkeysEnabled: true,
            bindings: defaultBindings
        )
    }

    func migratedToCurrentVersion() -> AppConfig {
        guard version < Self.currentVersion else { return self }

        var migrated = self

        if let chatGPTIndex = migrated.bindings.firstIndex(where: {
            $0.bundleIdentifier == "com.openai.codex"
        }) {
            migrated.bindings[chatGPTIndex].displayName = "ChatGPT"
            migrated.bindings[chatGPTIndex].appPath = "/Applications/ChatGPT.app"
        }

        for defaultBinding in Self.defaultBindings {
            let keyIsAlreadyBound = migrated.bindings.contains {
                $0.keyCode == defaultBinding.keyCode && $0.modifiers == defaultBinding.modifiers
            }
            let appIsAlreadyBound = migrated.bindings.contains {
                $0.bundleIdentifier == defaultBinding.bundleIdentifier
            }

            if !keyIsAlreadyBound && !appIsAlreadyBound {
                migrated.bindings.append(defaultBinding)
            }
        }

        migrated.version = Self.currentVersion
        return migrated
    }
}
