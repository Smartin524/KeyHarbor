import Foundation

final class ConfigStore {
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let customConfigURL: URL?

    init(fileManager: FileManager = .default, configURL: URL? = nil) {
        self.fileManager = fileManager
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.decoder = JSONDecoder()
        self.customConfigURL = configURL
    }

    func load() -> AppConfig {
        guard fileManager.fileExists(atPath: configURL.path) else {
            return .defaults()
        }

        do {
            let data = try Data(contentsOf: configURL)
            let decoded = try decoder.decode(AppConfig.self, from: data)
            let migrated = decoded.migratedToCurrentVersion()
            if migrated != decoded {
                try? save(migrated)
            }
            return migrated
        } catch {
            return .defaults()
        }
    }

    func save(_ config: AppConfig) throws {
        let directory = configURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(config)
        try data.write(to: configURL, options: .atomic)
    }

    private var configURL: URL {
        if let customConfigURL {
            return customConfigURL
        }
        return applicationSupportDirectory
            .appendingPathComponent("keyharbor", isDirectory: true)
            .appendingPathComponent("config.json")
    }

    private var applicationSupportDirectory: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        return base ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
    }
}
