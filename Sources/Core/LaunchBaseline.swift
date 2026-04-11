import Foundation
import os

/// Holds the display state captured when ScreenDial launched.
///
/// Recorded once in AppDelegate before any preset is applied; `restore()`
/// returns every online display to that captured state and clears the
/// active preset selection.
@MainActor
final class LaunchBaseline {
    static let shared = LaunchBaseline()

    private static let logger = Logger(subsystem: "com.ohresearch.screendial", category: "Baseline")

    private(set) var snapshot: DisplayStateSnapshot?

    private init() {}

    /// Captures the current display state. Safe to call multiple times —
    /// only the first call is honored so the baseline stays stable.
    ///
    /// Also clears any stale `activePresetID` persisted from the previous
    /// session — the OS resets gamma on process exit, so a carry-over
    /// checkmark would misrepresent the actual display state.
    func record() {
        guard snapshot == nil else {
            Self.logger.debug("Baseline already recorded — ignoring")
            return
        }
        PreferencesStore.shared.activePresetID = ""
        snapshot = DisplayStateSnapshot.capture(label: "Launch")
        Self.logger.info("Launch baseline recorded")
    }

    /// Restores every online display to the captured baseline state.
    func restore() {
        guard let snapshot else {
            Self.logger.warning("No baseline to restore")
            return
        }
        snapshot.restore()
    }
}
