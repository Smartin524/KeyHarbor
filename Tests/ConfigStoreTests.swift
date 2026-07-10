import Foundation

enum TestFailure: Error, CustomStringConvertible {
    case assertion(String)

    var description: String {
        switch self {
        case .assertion(let message):
            return message
        }
    }
}

@main
enum ConfigStoreTests {
    static func main() throws {
        try testRoundTripPreservesPausedStateAndBindings()
        try testLegacyBindingEnabledFieldDoesNotBreakDecoding()
        print("ConfigStoreTests: 2 passed")
    }

    private static func testRoundTripPreservesPausedStateAndBindings() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let store = ConfigStore(configURL: temporaryDirectory.appendingPathComponent("config.json"))
        let expected = AppConfig(
            version: AppConfig.currentVersion,
            hotkeysEnabled: false,
            bindings: [
                AppBinding(
                    displayName: "Test App",
                    bundleIdentifier: "com.example.test",
                    appPath: "/Applications/Test App.app",
                    keyCode: KeyCodes.t
                )
            ]
        )

        try store.save(expected)
        let loaded = store.load()
        let appState = AppState(store: store)

        try expect(loaded.version == expected.version, "config version did not round-trip")
        try expect(!loaded.hotkeysEnabled, "paused hotkey state did not round-trip")
        try expect(loaded.bindings == expected.bindings, "bindings did not round-trip")
        try expect(!appState.isHotkeysEnabled, "AppState ignored the persisted paused state")
        try expect(appState.bindings == expected.bindings, "AppState did not load persisted bindings")
    }

    private static func testLegacyBindingEnabledFieldDoesNotBreakDecoding() throws {
        let legacyJSON = """
        {
          "version": 1,
          "hotkeysEnabled": true,
          "bindings": [
            {
              "id": "00000000-0000-0000-0000-000000000001",
              "displayName": "Legacy App",
              "bundleIdentifier": "com.example.legacy",
              "appPath": "/Applications/Legacy.app",
              "keyCode": 13,
              "modifiers": 2048,
              "isEnabled": false
            }
          ]
        }
        """

        let config = try JSONDecoder().decode(AppConfig.self, from: Data(legacyJSON.utf8))

        try expect(config.bindings.count == 1, "legacy binding was not decoded")
        try expect(
            config.bindings[0].bundleIdentifier == "com.example.legacy",
            "legacy binding contents changed during decoding"
        )
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else { throw TestFailure.assertion(message) }
    }
}
