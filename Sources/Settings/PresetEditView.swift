import SwiftUI

struct PresetEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: DisplayPreset
    private let onSave: (DisplayPreset) -> Void

    init(preset: DisplayPreset, onSave: @escaping (DisplayPreset) -> Void) {
        _draft = State(initialValue: preset)
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Preset")
                .font(.title3)
                .fontWeight(.semibold)

            Form {
                // Name
                TextField("Name", text: $draft.name)

                // Brightness
                VStack(alignment: .leading) {
                    HStack {
                        Text("Brightness")
                        Spacer()
                        Text("\(Int(draft.brightness * 100))%")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $draft.brightness, in: 0...1, step: 0.01) {
                        Text("Brightness")
                    } minimumValueLabel: {
                        Image(systemName: "sun.min")
                    } maximumValueLabel: {
                        Image(systemName: "sun.max")
                    }
                }

                // Color Temperature
                VStack(alignment: .leading) {
                    HStack {
                        Text("Color Temperature")
                        Spacer()
                        Text(temperatureDisplayValue)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $draft.colorTemperature, in: -100...100, step: 1) {
                        Text("Color Temperature")
                    } minimumValueLabel: {
                        Text("Cool")
                            .font(.caption2)
                    } maximumValueLabel: {
                        Text("Warm")
                            .font(.caption2)
                    }
                }

                // Appearance Mode
                Picker("Appearance", selection: $draft.appearanceMode) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            .formStyle(.grouped)

            // Buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    onSave(draft)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 460, height: 480)
    }

    private var temperatureDisplayValue: String {
        let value = Int(draft.colorTemperature)
        if value > 0 { return "+\(value)" }
        return "\(value)"
    }
}
