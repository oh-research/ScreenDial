import CoreGraphics
import os

/// Controls display color temperature by adjusting RGB gamma curves.
///
/// Uses CGSetDisplayTransferByFormula (public CoreGraphics API) to shift
/// the color balance warm (reduce blue) or cool (reduce red). A temperature
/// value of 0 means neutral; -100 is maximum cool, +100 is maximum warm.
///
/// All operations fan out across every online display — preset application
/// applies the same triple everywhere, while snapshot restore uses a
/// per-display map to return each monitor to its own prior state.
@MainActor
enum GammaController {
    private static let logger = Logger(subsystem: "com.ohresearch.screendial", category: "Gamma")

    // MARK: - Public API

    /// Reads the current gamma coefficients from every online display.
    static func readCurrentGamma() -> [CGDirectDisplayID: GammaTriple] {
        var result: [CGDirectDisplayID: GammaTriple] = [:]
        for displayID in onlineDisplays() {
            if let triple = readGamma(for: displayID) {
                result[displayID] = triple
            }
        }
        return result
    }

    /// Applies the same gamma triple to every online display.
    static func applyGamma(_ triple: GammaTriple) {
        for displayID in onlineDisplays() {
            applyGamma(triple, to: displayID)
        }
    }

    /// Restores each display to its own previously captured gamma triple.
    /// Displays that are no longer online are silently skipped.
    static func restoreGammas(_ map: [CGDirectDisplayID: GammaTriple]) {
        let online = Set(onlineDisplays())
        for (displayID, triple) in map where online.contains(displayID) {
            applyGamma(triple, to: displayID)
        }
    }

    /// Applies a color temperature offset to every online display.
    ///
    /// - Parameter temperature: -100 (cool/blue) to +100 (warm/yellow). 0 is neutral.
    static func setColorTemperature(_ temperature: Double) {
        let clamped = min(max(temperature, -100), 100)
        let normalized = clamped / 100.0
        applyGamma(temperatureToRGB(normalized))
    }

    // MARK: - Per-display primitives

    private static func readGamma(for displayID: CGDirectDisplayID) -> GammaTriple? {
        var redMin: CGGammaValue = 0, redMax: CGGammaValue = 0, redGamma: CGGammaValue = 0
        var greenMin: CGGammaValue = 0, greenMax: CGGammaValue = 0, greenGamma: CGGammaValue = 0
        var blueMin: CGGammaValue = 0, blueMax: CGGammaValue = 0, blueGamma: CGGammaValue = 0

        let result = CGGetDisplayTransferByFormula(
            displayID,
            &redMin, &redMax, &redGamma,
            &greenMin, &greenMax, &greenGamma,
            &blueMin, &blueMax, &blueGamma
        )

        guard result == .success else {
            logger.error("Failed to read gamma for display \(displayID)")
            return nil
        }
        return GammaTriple(red: redMax, green: greenMax, blue: blueMax)
    }

    private static func applyGamma(_ triple: GammaTriple, to displayID: CGDirectDisplayID) {
        let result = CGSetDisplayTransferByFormula(
            displayID,
            0, triple.red, 1.0,
            0, triple.green, 1.0,
            0, triple.blue, 1.0
        )

        if result == .success {
            logger.debug("Gamma \(displayID): R=\(triple.red) G=\(triple.green) B=\(triple.blue)")
        } else {
            logger.error("Failed to set gamma for display \(displayID): error \(result.rawValue)")
        }
    }

    // MARK: - Display enumeration

    /// Returns all currently online displays (main + externals, mirrored or not).
    static func onlineDisplays() -> [CGDirectDisplayID] {
        var count: UInt32 = 0
        guard CGGetOnlineDisplayList(0, nil, &count) == .success, count > 0 else {
            return []
        }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetOnlineDisplayList(count, &ids, &count) == .success else {
            return []
        }
        return ids
    }

    // MARK: - Temperature → RGB Mapping

    /// Converts a normalized temperature value (-1.0 to +1.0) to RGB max coefficients.
    ///
    /// - Warm (+): reduces blue, slightly reduces green
    /// - Cool (-): reduces red, slightly reduces green
    /// - Neutral (0): all channels at 1.0
    private static func temperatureToRGB(_ normalized: Double) -> GammaTriple {
        if normalized >= 0 {
            return GammaTriple(
                red: 1.0,
                green: Float(1.0 - normalized * 0.1),
                blue: Float(1.0 - normalized * 0.3)
            )
        } else {
            let amount = -normalized
            return GammaTriple(
                red: Float(1.0 - amount * 0.3),
                green: Float(1.0 - amount * 0.1),
                blue: 1.0
            )
        }
    }
}
