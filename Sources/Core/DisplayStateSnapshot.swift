import CoreGraphics
import Foundation
import os

/// Raw gamma coefficients captured from the display hardware.
struct GammaTriple: Equatable, Sendable {
    let red: Float
    let green: Float
    let blue: Float
}

/// A point-in-time capture of every display property ScreenDial controls.
///
/// Snapshots are value types — taking one is side-effect free, and restoring
/// one re-applies all three properties (brightness, gamma, appearance). The
/// `activePresetID` is stored so the menu checkmark stays in sync with the
/// restored state.
struct DisplayStateSnapshot: Identifiable, Equatable, Sendable {
    let id: UUID
    let label: String
    let capturedAt: Date
    let brightness: [CGDirectDisplayID: Double]
    let gamma: [CGDirectDisplayID: GammaTriple]
    let appearance: AppearanceMode
    let activePresetID: String

    private static let logger = Logger(subsystem: "com.ohresearch.screendial", category: "Snapshot")

    @MainActor
    static func capture(label: String, activePresetID: String = "") -> DisplayStateSnapshot {
        DisplayStateSnapshot(
            id: UUID(),
            label: label,
            capturedAt: Date(),
            brightness: BrightnessController.snapshotBrightness(),
            gamma: GammaController.readCurrentGamma(),
            appearance: AppearanceController.currentAppearance(),
            activePresetID: activePresetID
        )
    }

    @MainActor
    func restore() {
        Self.logger.info("Restoring snapshot: \(label)")

        BrightnessController.restoreBrightnesses(brightness)
        GammaController.restoreGammas(gamma)

        if AppearanceController.currentAppearance() != appearance,
           AppearanceController.hasPermission {
            AppearanceController.setAppearance(appearance)
        }

        PreferencesStore.shared.activePresetID = activePresetID
    }

    static func == (lhs: DisplayStateSnapshot, rhs: DisplayStateSnapshot) -> Bool {
        lhs.id == rhs.id
    }
}
