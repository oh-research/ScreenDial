import Cocoa
import os

/// Monitors Accessibility permission state for AppleScript automation.
///
/// Polls periodically to detect permission grants or revocations.
/// Only Accessibility is needed — brightness and gamma control require no permissions.
@MainActor
final class PermissionManager: ObservableObject {
    static let shared = PermissionManager()

    private static let logger = Logger(subsystem: "com.ohresearch.screendial", category: "Permission")
    private var pollTimer: Timer?

    @Published private(set) var isAccessibilityGranted: Bool = false

    private init() {
        checkPermission()
    }

    /// Checks the current Accessibility permission state.
    func checkPermission() {
        isAccessibilityGranted = AXIsProcessTrusted()
    }

    /// Prompts the user for Accessibility permission (shows system dialog).
    func requestPermission() {
        let options = [
            "AXTrustedCheckOptionPrompt": true
        ] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        startPolling()
    }

    /// Opens System Settings > Privacy > Accessibility.
    func openAccessibilitySettings() {
        let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        )!
        NSWorkspace.shared.open(url)
        startPolling()
    }

    /// Starts polling every 2 seconds to detect permission changes.
    func startPolling() {
        guard pollTimer == nil else { return }

        Self.logger.debug("Started permission polling")
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPermission()
                if self?.isAccessibilityGranted == true {
                    self?.stopPolling()
                }
            }
        }
    }

    /// Stops the permission polling timer.
    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
        Self.logger.debug("Stopped permission polling")
    }
}
