import Foundation

/// Loads and saves `AppConfig` as JSON in Application Support. Fully local; no network.
enum ConfigStore {
    static var supportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("OpenLid", isDirectory: true)
    }

    static var configURL: URL {
        supportDirectory.appendingPathComponent("config.json")
    }

    static func load() -> AppConfig {
        guard let data = try? Data(contentsOf: configURL) else { return AppConfig() }
        do {
            return try JSONDecoder().decode(AppConfig.self, from: data)
        } catch {
            NSLog("OpenLid: failed to decode config, using defaults: \(error)")
            return AppConfig()
        }
    }

    static func save(_ config: AppConfig) {
        do {
            try FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            try data.write(to: configURL, options: .atomic)
        } catch {
            NSLog("OpenLid: failed to save config: \(error)")
        }
    }
}
