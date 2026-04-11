import CoreGraphics
import os

/// Controls display brightness via CoreDisplay private API.
///
/// CoreDisplay_Display_SetUserBrightness is loaded dynamically since the
/// framework has no public headers. Operations fan out across every online
/// display; unsupported externals (most non-Apple monitors) silently no-op
/// at the CoreDisplay layer.
@MainActor
enum BrightnessController {
    private static let logger = Logger(subsystem: "com.ohresearch.screendial", category: "Brightness")

    // MARK: - CoreDisplay function pointers

    private static let coreDisplayHandle: UnsafeMutableRawPointer? = {
        dlopen("/System/Library/Frameworks/CoreDisplay.framework/CoreDisplay", RTLD_LAZY)
    }()

    private typealias SetBrightnessFn = @convention(c) (CGDirectDisplayID, Double) -> Void
    private typealias GetBrightnessFn = @convention(c) (CGDirectDisplayID) -> Double

    private static let setBrightnessPtr: SetBrightnessFn? = {
        guard let handle = coreDisplayHandle,
              let sym = dlsym(handle, "CoreDisplay_Display_SetUserBrightness") else { return nil }
        return unsafeBitCast(sym, to: SetBrightnessFn.self)
    }()

    private static let getBrightnessPtr: GetBrightnessFn? = {
        guard let handle = coreDisplayHandle,
              let sym = dlsym(handle, "CoreDisplay_Display_GetUserBrightness") else { return nil }
        return unsafeBitCast(sym, to: GetBrightnessFn.self)
    }()

    // MARK: - Public API

    /// Reads the current brightness on every online display that reports a
    /// valid value. Displays that don't support brightness control return
    /// nonsense values, which we filter out.
    static func snapshotBrightness() -> [CGDirectDisplayID: Double] {
        guard let getBrightness = getBrightnessPtr else {
            logger.error("CoreDisplay API unavailable")
            return [:]
        }

        var result: [CGDirectDisplayID: Double] = [:]
        for displayID in GammaController.onlineDisplays() {
            let value = getBrightness(displayID)
            if value.isFinite, (0...1).contains(value) {
                result[displayID] = value
            }
        }
        return result
    }

    /// Sets the given brightness on every online display. Value is clamped to 0.0–1.0.
    static func setBrightness(_ value: Double) {
        let clamped = min(max(value, 0), 1)
        guard let setBrightness = setBrightnessPtr else {
            logger.error("CoreDisplay API unavailable")
            return
        }
        for displayID in GammaController.onlineDisplays() {
            setBrightness(displayID, clamped)
        }
        logger.debug("Brightness set to \(clamped, format: .fixed(precision: 2)) on all displays")
    }

    /// Restores per-display brightness from a previously captured snapshot.
    /// Displays that are no longer online are silently skipped.
    static func restoreBrightnesses(_ map: [CGDirectDisplayID: Double]) {
        guard let setBrightness = setBrightnessPtr else {
            logger.error("CoreDisplay API unavailable")
            return
        }
        let online = Set(GammaController.onlineDisplays())
        for (displayID, value) in map where online.contains(displayID) {
            setBrightness(displayID, min(max(value, 0), 1))
        }
    }

    /// Returns the main display's brightness (used to seed new presets in the UI).
    static func getMainBrightness() -> Double? {
        guard let getBrightness = getBrightnessPtr else { return nil }
        let value = getBrightness(CGMainDisplayID())
        return value.isFinite ? value : nil
    }

    /// Whether the CoreDisplay brightness API is available on this system.
    static var isAvailable: Bool {
        setBrightnessPtr != nil
    }
}
