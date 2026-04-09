import SwiftUI

struct SettingsView: View {
    @ObservedObject var configManager: ConfigManager

    var body: some View {
        TabView {
            PresetListView(configManager: configManager)
                .tabItem { Label("Presets", systemImage: "slider.horizontal.3") }

            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }
        }
        .frame(width: 520, height: 520)
    }
}

// MARK: - General Settings

private struct GeneralSettingsView: View {
    @State private var launchAtLogin = LoginItemHelper.isEnabled

    var body: some View {
        Form {
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    LoginItemHelper.setEnabled(newValue)
                }
        }
        .formStyle(.grouped)
        .padding()
    }
}
