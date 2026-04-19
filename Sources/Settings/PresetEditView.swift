import SwiftUI

struct PresetEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: DisplayPreset
    @State private var preview = PreviewCoordinator()
    private let onSave: (DisplayPreset) -> Void

    init(preset: DisplayPreset, onSave: @escaping (DisplayPreset) -> Void) {
        _draft = State(initialValue: preset)
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Edit Preset")
                .font(.title3)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)

            TextField("Name", text: $draft.name)
                .textFieldStyle(.roundedBorder)

            brightnessSection
            temperatureSection
            appearanceSection

            Spacer()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 460, height: 440)
        .onAppear { preview.start() }
        .onChange(of: draft) { _, new in preview.apply(new) }
        .onDisappear { preview.cancel() }
    }

    private var brightnessSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Brightness")
                Spacer()
                Text("\(Int(draft.brightness * 100))%")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: $draft.brightness, in: 0...1) {
                Text("Brightness")
            } minimumValueLabel: {
                Image(systemName: "sun.min")
            } maximumValueLabel: {
                Image(systemName: "sun.max")
            }
            .labelsHidden()
        }
    }

    private var temperatureSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Color Temperature")
                Spacer()
                Text(temperatureDisplayValue)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: $draft.colorTemperature, in: -100...100) {
                Text("Color Temperature")
            } minimumValueLabel: {
                Text("Cool").font(.caption2)
            } maximumValueLabel: {
                Text("Warm").font(.caption2)
            }
            .labelsHidden()
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Appearance")
            Picker("Appearance", selection: $draft.appearanceMode) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private func save() {
        onSave(draft)
        let isActive = PreferencesStore.shared.activePresetID == draft.id.uuidString
        if isActive {
            preview.commit()
        }
        dismiss()
    }

    private var temperatureDisplayValue: String {
        let value = Int(draft.colorTemperature)
        if value > 0 { return "+\(value)" }
        return "\(value)"
    }
}
