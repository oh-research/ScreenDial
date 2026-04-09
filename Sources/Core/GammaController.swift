import CoreGraphics
import os

/// Controls display color temperature by adjusting RGB gamma curves.
///
/// Uses CGSetDisplayTransferByFormula (public CoreGraphics API) to shift
/// the color balance warm (reduce blue) or cool (reduce red). A temperature
/// value of 0 means neutral; -100 is maximum cool, +100 is maximum warm.
@MainActor
enum GammaController {
    private static let logger = Logger(subsystem: "com.ohresearch.screendial", category: "Gamma")

    /// Saved original gamma values for safe restoration.
    private static var savedRedMax: Float = 1.0
    private static var savedGreenMax: Float = 1.0
    private static var savedBlueMax: Float = 1.0

    // MARK: - Public API

    /// Saves the current gamma state so it can be restored later.
    static func saveCurrentGamma() {
        var redMin: CGGammaValue = 0, redMax: CGGammaValue = 0, redGamma: CGGammaValue = 0
        var greenMin: CGGammaValue = 0, greenMax: CGGammaValue = 0, greenGamma: CGGammaValue = 0
        var blueMin: CGGammaValue = 0, blueMax: CGGammaValue = 0, blueGamma: CGGammaValue = 0

        let result = CGGetDisplayTransferByFormula(
            CGMainDisplayID(),
            &redMin, &redMax, &redGamma,
            &greenMin, &greenMax, &greenGamma,
            &blueMin, &blueMax, &blueGamma
        )

        if result == .success {
            savedRedMax = redMax
            savedGreenMax = greenMax
            savedBlueMax = blueMax
            logger.debug("Gamma saved: R=\(redMax) G=\(greenMax) B=\(blueMax)")
        } else {
            logger.error("Failed to read current gamma")
        }
    }

    /// Applies a color temperature offset to the display.
    ///
    /// - Parameter temperature: -100 (cool/blue) to +100 (warm/yellow). 0 is neutral.
    static func setColorTemperature(_ temperature: Double) {
        let clamped = min(max(temperature, -100), 100)
        let normalized = clamped / 100.0 // -1.0 to +1.0
        let coefficients = temperatureToRGB(normalized)

        let displayID = CGMainDisplayID()
        let result = CGSetDisplayTransferByFormula(
            displayID,
            0, coefficients.red, 1.0,
            0, coefficients.green, 1.0,
            0, coefficients.blue, 1.0
        )

        if result == .success {
            logger.debug("Color temperature set to \(clamped, format: .fixed(precision: 0))")
        } else {
            logger.error("Failed to set gamma: error \(result.rawValue)")
        }
    }

    /// Restores gamma to the previously saved state.
    /// Uses saved values instead of CGDisplayRestoreColorSyncSettings to avoid the blackout bug.
    static func restoreGamma() {
        let displayID = CGMainDisplayID()
        let result = CGSetDisplayTransferByFormula(
            displayID,
            0, savedRedMax, 1.0,
            0, savedGreenMax, 1.0,
            0, savedBlueMax, 1.0
        )

        if result == .success {
            logger.debug("Gamma restored")
        } else {
            logger.error("Failed to restore gamma")
        }
    }

    /// Resets gamma to system default (all channels at 1.0).
    static func resetToDefault() {
        let displayID = CGMainDisplayID()
        CGSetDisplayTransferByFormula(displayID, 0, 1.0, 1.0, 0, 1.0, 1.0, 0, 1.0, 1.0)
        logger.debug("Gamma reset to default")
    }

    // MARK: - Temperature → RGB Mapping

    /// Converts a normalized temperature value (-1.0 to +1.0) to RGB max coefficients.
    ///
    /// - Warm (+): reduces blue, slightly reduces green
    /// - Cool (-): reduces red, slightly reduces green
    /// - Neutral (0): all channels at 1.0
    private static func temperatureToRGB(_ normalized: Double) -> (red: Float, green: Float, blue: Float) {
        if normalized >= 0 {
            // Warm: reduce blue
            let red: Float = 1.0
            let green: Float = Float(1.0 - normalized * 0.1)
            let blue: Float = Float(1.0 - normalized * 0.3)
            return (red, green, blue)
        } else {
            // Cool: reduce red
            let amount = -normalized
            let red: Float = Float(1.0 - amount * 0.3)
            let green: Float = Float(1.0 - amount * 0.1)
            let blue: Float = 1.0
            return (red, green, blue)
        }
    }
}
