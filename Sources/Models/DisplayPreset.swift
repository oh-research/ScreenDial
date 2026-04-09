import Foundation

/// The appearance mode to apply when a preset is activated.
enum AppearanceMode: String, Codable, Sendable, CaseIterable {
    case light
    case dark

    var displayName: String {
        switch self {
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}

/// A saved display configuration that can be applied with one click.
struct DisplayPreset: Identifiable, Codable, Sendable, Equatable {
    var id: UUID
    var name: String

    /// Display brightness. Range: 0.0 (minimum) to 1.0 (maximum).
    var brightness: Double

    /// Color temperature offset. Range: -100 (cool/blue) to +100 (warm/yellow).
    /// 0 means neutral (no gamma adjustment).
    var colorTemperature: Double

    /// System appearance mode to apply.
    var appearanceMode: AppearanceMode

    init(
        id: UUID = UUID(),
        name: String,
        brightness: Double = 0.5,
        colorTemperature: Double = 0,
        appearanceMode: AppearanceMode = .light
    ) {
        self.id = id
        self.name = name
        self.brightness = brightness.clamped(to: 0...1)
        self.colorTemperature = colorTemperature.clamped(to: -100...100)
        self.appearanceMode = appearanceMode
    }
}

/// Versioned container for JSON persistence.
struct PresetConfig: Codable {
    var version: Int = 1
    var presets: [DisplayPreset]
}

// MARK: - Helpers

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
