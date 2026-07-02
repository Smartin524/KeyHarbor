import Foundation

final class ConfigStore {
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.decoder = JSONDecoder()
    }

    func load() -> AppConfig {
        guard fileManager.fileExists(atPath: configURL.path) else {
            return .defaults()
        }

        do {
            let data = try Data(contentsOf: configURL)
            return try decoder.decode(AppConfig.self, from: data)
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
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let directory = base ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        return directory
            .appendingPathComponent("QuickXia", isDirectory: true)
            .appendingPathComponent("config.json")
    }
}
