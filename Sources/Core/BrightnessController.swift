import CoreGraphics
import os

/// Controls the built-in display brightness via CoreDisplay private API.
///
/// CoreDisplay_Display_SetUserBrightness is loaded dynamically since the
/// framework has no public headers. Falls back to IOKit if unavailable.
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

    /// Sets the built-in display brightness. Value is clamped to 0.0–1.0.
    static func setBrightness(_ value: Double) {
        let clamped = min(max(value, 0), 1)
        let displayID = CGMainDisplayID()

        if let setBrightness = setBrightnessPtr {
            setBrightness(displayID, clamped)
            logger.debug("Brightness set to \(clamped, format: .fixed(precision: 2))")
        } else {
            logger.error("CoreDisplay API unavailable")
        }
    }

    /// Returns the current built-in display brightness (0.0–1.0), or nil if unavailable.
    static func getBrightness() -> Double? {
        let displayID = CGMainDisplayID()

        if let getBrightness = getBrightnessPtr {
            return getBrightness(displayID)
        }

        logger.error("CoreDisplay API unavailable")
        return nil
    }

    /// Whether the CoreDisplay brightness API is available on this system.
    static var isAvailable: Bool {
        setBrightnessPtr != nil
    }
}
