import Foundation
import os

@MainActor
final class ConfigManager: ObservableObject {
    private static let logger = Logger(subsystem: "com.ohresearch.screendial", category: "ConfigManager")
    private static let currentVersion = 1

    private let configURL: URL
    @Published private(set) var presets: [DisplayPreset] = []

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let appDir = appSupport.appendingPathComponent("ScreenDial", isDirectory: true)

        if !FileManager.default.fileExists(atPath: appDir.path) {
            try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        }

        self.configURL = appDir.appendingPathComponent("presets.json")
        load()
    }

    // MARK: - Persistence

    func load() {
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            Self.logger.info("No config file found, creating default presets")
            presets = Self.defaultPresets
            save()
            return
        }

        do {
            let data = try Data(contentsOf: configURL)
            var decoded = try JSONDecoder().decode(PresetConfig.self, from: data)

            if decoded.version != Self.currentVersion {
                Self.logger.warning("Config version mismatch: \(decoded.version) → \(Self.currentVersion)")
                decoded = migrate(from: decoded)
            }

            self.presets = decoded.presets.isEmpty ? Self.defaultPresets : decoded.presets
            if decoded.presets.isEmpty {
                save()
                Self.logger.info("Config was empty, created default presets")
            } else {
                Self.logger.info("Loaded \(decoded.presets.count) presets")
            }
        } catch {
            Self.logger.error("Failed to load config: \(error.localizedDescription)")
        }
    }

    func save() {
        let config = PresetConfig(version: Self.currentVersion, presets: presets)

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            try data.write(to: configURL, options: .atomic)
            Self.logger.info("Saved \(self.presets.count) presets")
        } catch {
            Self.logger.error("Failed to save config: \(error.localizedDescription)")
        }
    }

    // MARK: - Migration

    private func migrate(from old: PresetConfig) -> PresetConfig {
        Self.logger.info("Migration complete: v\(old.version) → v\(Self.currentVersion)")
        var migrated = old
        migrated.version = Self.currentVersion
        return migrated
    }

    // MARK: - Default Presets

    private static let defaultPresets: [DisplayPreset] = [
        DisplayPreset(name: "작업 모드", brightness: 0.8, colorTemperature: 0, appearanceMode: .light),
        DisplayPreset(name: "야간 모드", brightness: 0.3, colorTemperature: 70, appearanceMode: .dark),
        DisplayPreset(name: "영화 감상", brightness: 0.4, colorTemperature: 30, appearanceMode: .dark),
        DisplayPreset(name: "프레젠테이션", brightness: 1.0, colorTemperature: 0, appearanceMode: .light),
    ]

    // MARK: - Mutation

    func addPreset(_ preset: DisplayPreset) {
        presets.append(preset)
        save()
    }

    func updatePreset(_ preset: DisplayPreset) {
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[index] = preset
            save()
        }
    }

    func removePreset(id: UUID) {
        presets.removeAll { $0.id == id }
        save()
    }

    func movePreset(from source: IndexSet, to destination: Int) {
        presets.move(fromOffsets: source, toOffset: destination)
        save()
    }
}
