import AppKit
import SwiftUI

struct OnboardingView: View {
    @ObservedObject private var permission = PermissionManager.shared
    @ObservedObject private var preferences = PreferencesStore.shared

    var body: some View {
        VStack(spacing: 20) {
            Text("How to Use ScreenDial")
                .font(.title2)
                .fontWeight(.semibold)

            GroupBox("How to use") {
                VStack(alignment: .leading, spacing: 10) {
                    HowToRow(
                        icon: "slider.horizontal.3",
                        text: "Create presets in Settings with brightness, color temperature, and appearance mode"
                    )
                    HowToRow(
                        icon: "cursorarrow.click",
                        text: "Click a preset name in the menu bar to apply it instantly"
                    )
                    HowToRow(
                        icon: "pencil",
                        text: "Edit preset names and values anytime in Settings"
                    )
                }
                .padding(.vertical, 4)
            }

            OnboardingProgressView(steps: [
                .init(title: "Accessibility", completed: permission.isAccessibilityGranted)
            ])
            .padding(.horizontal, 12)

            VStack(spacing: 10) {
                PermissionCardView(
                    icon: "accessibility",
                    title: "Accessibility",
                    description: "Required for dark/light mode switching. Brightness and color temperature work without it.",
                    granted: permission.isAccessibilityGranted,
                    primaryAction: { permission.requestPermission() },
                    fallbackAction: { permission.openAccessibilitySettings() }
                )
            }

            if preferences.onboardingCompleted {
                Button("Close") { completeOnboarding() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
            } else {
                Button("Get Started") { completeOnboarding() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 440)
        .onAppear {
            permission.checkPermission()
            if !permission.isAccessibilityGranted {
                permission.startPolling()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            permission.checkPermission()
        }
    }

    private func completeOnboarding() {
        preferences.onboardingCompleted = true
        NSApp.keyWindow?.close()
    }
}
