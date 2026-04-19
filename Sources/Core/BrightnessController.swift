import CoreGraphics
import os

/// Controls display brightness via DisplayServices private API.
///
/// `DisplayServicesSetBrightness` is loaded dynamically since the framework
/// has no public headers. On modern macOS (14+) the older
/// `CoreDisplay_Display_SetUserBrightness` is a silent no-op on internal
/// Apple Silicon displays, so DisplayServices is the only path that works
/// for both internal and supported external monitors.
///
/// Operations fan out across every online display; unsupported monitors
/// return a non-zero OSStatus and are silently skipped.
@MainActor
enum BrightnessController {
    private static let logger = Logger(subsystem: "com.ohresearch.screendial", category: "Brightness")

    // MARK: - DisplayServices function pointers

    private static let handle: UnsafeMutableRawPointer? = {
        dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY)
    }()

    private typealias SetBrightnessFn = @convention(c) (CGDirectDisplayID, Float) -> Int32
    private typealias GetBrightnessFn = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32

    private static let setBrightnessPtr: SetBrightnessFn? = {
        guard let handle, let sym = dlsym(handle, "DisplayServicesSetBrightness") else { return nil }
        return unsafeBitCast(sym, to: SetBrightnessFn.self)
    }()

    private static let getBrightnessPtr: GetBrightnessFn? = {
        guard let handle, let sym = dlsym(handle, "DisplayServicesGetBrightness") else { return nil }
        return unsafeBitCast(sym, to: GetBrightnessFn.self)
    }()

    // MARK: - Public API

    /// Reads the current brightness on every online display that reports a valid value.
    static func snapshotBrightness() -> [CGDirectDisplayID: Double] {
        var result: [CGDirectDisplayID: Double] = [:]
        for displayID in GammaController.onlineDisplays() {
            if let value = readBrightness(displayID) {
                result[displayID] = value
            }
        }
        return result
    }

    /// Sets the given brightness on every online display. Value is clamped to 0.0–1.0.
    static func setBrightness(_ value: Double) {
        let clamped = min(max(value, 0), 1)
        guard let setBrightness = setBrightnessPtr else {
            logger.error("DisplayServices API unavailable — SetBrightness symbol not found")
            return
        }
        var applied = 0
        for displayID in GammaController.onlineDisplays() {
            let status = setBrightness(displayID, Float(clamped))
            if status == 0 { applied += 1 }
        }
        logger.info("Brightness set to \(clamped, format: .fixed(precision: 2)) on \(applied) display(s)")
    }

    /// Restores per-display brightness from a previously captured snapshot.
    /// Displays that are no longer online are silently skipped.
    static func restoreBrightnesses(_ map: [CGDirectDisplayID: Double]) {
        guard let setBrightness = setBrightnessPtr else {
            logger.error("DisplayServices API unavailable")
            return
        }
        let online = Set(GammaController.onlineDisplays())
        for (displayID, value) in map where online.contains(displayID) {
            _ = setBrightness(displayID, Float(min(max(value, 0), 1)))
        }
    }

    /// Returns the main display's brightness (used to seed new presets in the UI).
    static func getMainBrightness() -> Double? {
        readBrightness(CGMainDisplayID())
    }

    /// Whether the DisplayServices brightness API is available on this system.
    static var isAvailable: Bool {
        setBrightnessPtr != nil
    }

    // MARK: - Private

    private static func readBrightness(_ displayID: CGDirectDisplayID) -> Double? {
        guard let getBrightness = getBrightnessPtr else { return nil }
        var value: Float = 0
        let status = getBrightness(displayID, &value)
        guard status == 0, value.isFinite, (0...1).contains(value) else { return nil }
        return Double(value)
    }
}
