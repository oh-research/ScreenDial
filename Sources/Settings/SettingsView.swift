import SwiftUI

struct SettingsView: View {
    @ObservedObject var configManager: ConfigManager

    var body: some View {
        VStack(spacing: 0) {
            LaunchAtLoginRow()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Divider()

            PresetListView(configManager: configManager)
        }
        .frame(width: 520, height: 520)
    }
}

// MARK: - Launch at Login Row

private struct LaunchAtLoginRow: View {
    @State private var isEnabled = LoginItemHelper.isEnabled

    var body: some View {
        Toggle("Launch at Login", isOn: $isEnabled)
            .toggleStyle(.switch)
            .onChange(of: isEnabled) { _, newValue in
                LoginItemHelper.setEnabled(newValue)
            }
    }
}
