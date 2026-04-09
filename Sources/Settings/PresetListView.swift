import SwiftUI

struct PresetListView: View {
    @ObservedObject var configManager: ConfigManager
    @State private var selectedPresetID: UUID?
    @State private var editingPreset: DisplayPreset?

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selectedPresetID) {
                ForEach(configManager.presets) { preset in
                    PresetRow(preset: preset)
                        .tag(preset.id)
                        .onTapGesture(count: 2) {
                            editingPreset = preset
                        }
                }
                .onMove { source, destination in
                    configManager.movePreset(from: source, to: destination)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))

            // Toolbar at bottom
            HStack(spacing: 12) {
                Button(action: addPreset) {
                    Label("Add", systemImage: "plus")
                }
                .controlSize(.regular)

                Button(action: removeSelectedPreset) {
                    Label("Remove", systemImage: "minus")
                }
                .controlSize(.regular)
                .disabled(selectedPresetID == nil)

                Spacer()

                Button {
                    if let id = selectedPresetID,
                       let preset = configManager.presets.first(where: { $0.id == id }) {
                        editingPreset = preset
                    }
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .controlSize(.regular)
                .disabled(selectedPresetID == nil)
            }
            .padding(12)
            .background(.bar)
        }
        .sheet(item: $editingPreset) { preset in
            PresetEditView(preset: preset) { updated in
                configManager.updatePreset(updated)
            }
        }
    }

    private func addPreset() {
        let preset = DisplayPreset(
            name: "New Preset",
            brightness: BrightnessController.getBrightness() ?? 0.5,
            colorTemperature: 0,
            appearanceMode: AppearanceController.currentAppearance()
        )
        configManager.addPreset(preset)
        selectedPresetID = preset.id
        editingPreset = preset
    }

    private func removeSelectedPreset() {
        guard let id = selectedPresetID else { return }
        configManager.removePreset(id: id)
        selectedPresetID = nil
    }
}

// MARK: - PresetRow

private struct PresetRow: View {
    let preset: DisplayPreset

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(preset.name)
                    .font(.body)

                HStack(spacing: 8) {
                    Label(
                        "\(Int(preset.brightness * 100))%",
                        systemImage: "sun.max"
                    )
                    Label(
                        temperatureLabel,
                        systemImage: "thermometer.medium"
                    )
                    Label(
                        preset.appearanceMode.displayName,
                        systemImage: preset.appearanceMode == .dark
                            ? "moon.fill" : "sun.max.fill"
                    )
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private var temperatureLabel: String {
        let value = Int(preset.colorTemperature)
        if value > 0 { return "+\(value) warm" }
        if value < 0 { return "\(value) cool" }
        return "neutral"
    }
}
