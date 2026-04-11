import os

/// Applies all three display properties of a preset in sequence:
/// brightness → color temperature → appearance mode.
///
/// Each step is independent — if one fails, the others still apply.
@MainActor
enum PresetApplicator {
    private static let logger = Logger(subsystem: "com.ohresearch.screendial", category: "PresetApplicator")

    /// Applies the given preset to the built-in display.
    static func apply(_ preset: DisplayPreset) {
        logger.info("Applying preset: \(preset.name)")

        // 1. Brightness
        BrightnessController.setBrightness(preset.brightness)

        // 2. Color temperature
        GammaController.setColorTemperature(preset.colorTemperature)

        // 3. Appearance mode (requires Accessibility permission)
        if AppearanceController.hasPermission {
            AppearanceController.setAppearance(preset.appearanceMode)
        } else {
            logger.warning("Skipping appearance change — Accessibility permission not granted")
        }

        logger.info("Preset applied: \(preset.name)")
    }

    /// Restores the display to the launch baseline captured when ScreenDial started.
    /// Brightness, gamma, and appearance are all reverted.
    static func deactivate() {
        logger.info("Deactivating preset — restoring launch baseline")
        LaunchBaseline.shared.restore()
    }
}
