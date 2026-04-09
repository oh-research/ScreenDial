import Cocoa
import os

/// Controls macOS system appearance (dark/light mode) via AppleScript.
///
/// Requires Accessibility permission (AXIsProcessTrusted).
/// If permission is not granted, operations fail silently with a log warning.
@MainActor
enum AppearanceController {
    private static let logger = Logger(subsystem: "com.ohresearch.screendial", category: "Appearance")

    /// Sets the system appearance to dark or light mode.
    static func setAppearance(_ mode: AppearanceMode) {
        let isDark = mode == .dark
        let script = """
            tell application "System Events"
                tell appearance preferences
                    set dark mode to \(isDark)
                end tell
            end tell
            """

        guard let appleScript = NSAppleScript(source: script) else {
            logger.error("Failed to create AppleScript")
            return
        }

        var errorInfo: NSDictionary?
        appleScript.executeAndReturnError(&errorInfo)

        if let error = errorInfo {
            logger.warning("AppleScript error: \(error)")
        } else {
            logger.debug("Appearance set to \(mode.rawValue)")
        }
    }

    /// Returns the current system appearance mode.
    static func currentAppearance() -> AppearanceMode {
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        return isDark ? .dark : .light
    }

    /// Whether Accessibility permission is granted (required for AppleScript automation).
    static var hasPermission: Bool {
        AXIsProcessTrusted()
    }
}
