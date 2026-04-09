import SwiftUI

struct OnboardingView: View {
    @ObservedObject private var permission = PermissionManager.shared
    @ObservedObject private var preferences = PreferencesStore.shared

    var body: some View {
        VStack(spacing: 24) {
            Text("How to Use ScreenDial")
                .font(.title2)
                .fontWeight(.semibold)

            // How to use
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

            // Permissions
            GroupBox("Permissions") {
                VStack(spacing: 12) {
                    PermissionRow(
                        granted: permission.isAccessibilityGranted,
                        title: "Accessibility",
                        description: "Required for dark/light mode switching. Brightness and color temperature work without it.",
                        action: { permission.openAccessibilitySettings() }
                    )
                }
                .padding(.vertical, 4)
            }

            // Done
            Button(preferences.onboardingCompleted ? "Close" : "Get Started") {
                preferences.onboardingCompleted = true
                NSApp.keyWindow?.close()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(width: 380)
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
}

// MARK: - Components

private struct PermissionRow: View {
    let granted: Bool
    let title: String
    let description: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: granted ? "checkmark.shield.fill" : "shield.lefthalf.filled")
                .font(.title2)
                .foregroundStyle(granted ? .green : .orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(granted ? "Permission granted" : description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !granted {
                Button("Grant Access") { action() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
    }
}

private struct HowToRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.blue)
            Text(text)
                .font(.subheadline)
        }
    }
}
