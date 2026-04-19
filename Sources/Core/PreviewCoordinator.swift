import Foundation
import os

/// Drives the live hardware preview while a preset is being edited.
///
/// `start()` captures a baseline snapshot; `apply(_:)` pushes draft values to
/// the display so the user sees the exact result; `cancel()` rewinds to the
/// baseline. `commit()` ends preview without reverting — used when the edited
/// preset is the currently active one and the new values should stay on screen.
///
/// Appearance transitions are skipped when the value hasn't changed because
/// the AppleScript dark/light toggle is slow and visually jarring.
@MainActor
final class PreviewCoordinator {
    private static let logger = Logger(subsystem: "com.ohresearch.screendial", category: "Preview")

    private var baseline: DisplayStateSnapshot?
    private var lastAppearance: AppearanceMode?

    func start() {
        guard baseline == nil else { return }
        let snapshot = DisplayStateSnapshot.capture(
            label: "PreviewEdit",
            activePresetID: PreferencesStore.shared.activePresetID
        )
        baseline = snapshot
        lastAppearance = snapshot.appearance
        Self.logger.info("Preview baseline captured")
    }

    func apply(_ draft: DisplayPreset) {
        guard baseline != nil else {
            Self.logger.warning("apply() called before start() — skipped")
            return
        }

        Self.logger.info("Preview apply: brightness=\(draft.brightness, format: .fixed(precision: 2)) temp=\(draft.colorTemperature, format: .fixed(precision: 0)) appearance=\(draft.appearanceMode.rawValue, privacy: .public) last=\(self.lastAppearance?.rawValue ?? "nil", privacy: .public)")

        BrightnessController.setBrightness(draft.brightness)
        GammaController.setColorTemperature(draft.colorTemperature)

        if draft.appearanceMode != lastAppearance {
            if AppearanceController.hasPermission {
                Self.logger.info("Applying appearance change: \(draft.appearanceMode.rawValue, privacy: .public)")
                AppearanceController.setAppearance(draft.appearanceMode)
                lastAppearance = draft.appearanceMode
            } else {
                Self.logger.warning("Appearance preview skipped — Accessibility permission not granted")
            }
        }
    }

    func cancel() {
        guard let baseline else { return }
        Self.logger.info("Restoring preview baseline")
        baseline.restore()
        clear()
    }

    func commit() {
        guard baseline != nil else { return }
        Self.logger.info("Committing preview — leaving current state on display")
        clear()
    }

    private func clear() {
        baseline = nil
        lastAppearance = nil
    }
}
