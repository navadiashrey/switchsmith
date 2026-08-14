import SwiftUI

struct DesignerView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Switch Designer")
                .font(.title2.bold())
            Text("Every click below is synthesized live — nothing here is a recording.")
                .font(.callout)
                .foregroundStyle(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Presets").font(.headline)
                HStack(spacing: 8) {
                    ForEach(SwitchPresets.all) { preset in
                        Button(preset.name) {
                            appState.applyPreset(preset)
                            appState.previewClick()
                        }
                        .buttonStyle(.bordered)
                        .tint(appState.selectedPresetID == preset.id ? .accentColor : .secondary)
                    }
                }
                if let id = appState.selectedPresetID,
                   let preset = SwitchPresets.all.first(where: { $0.id == id }) {
                    Text(preset.blurb)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                slider("Sharpness", paramBinding(\.sharpness), "Soft tap", "Sharp snap")
                slider("Weight", paramBinding(\.weight), "Light", "Heavy bottom-out")
                slider("Brightness", paramBinding(\.brightness), "Muted", "Crisp")
                slider("Decay", paramBinding(\.decay), "Tight", "Ringing", range: 0.02...0.25)
                slider("Jitter", paramBinding(\.jitter), "Consistent", "Organic")
                slider("Volume", paramBinding(\.volume), "Quiet", "Loud")
            }

            Divider()

            HStack {
                Button("Preview Click") { appState.previewClick() }
                    .buttonStyle(.borderedProminent)
                Spacer()
                Toggle("Enabled", isOn: $appState.isEnabled)
            }
        }
        .padding(20)
        .frame(width: 420)
    }

    /// Binds directly to a parameter field. Setting it manually (as opposed
    /// to via `applyPreset`) marks the current selection as a custom, unnamed
    /// preset by clearing `selectedPresetID`.
    private func paramBinding(_ keyPath: WritableKeyPath<SwitchParameters, Float>) -> Binding<Float> {
        Binding(
            get: { appState.parameters[keyPath: keyPath] },
            set: { newValue in
                appState.parameters[keyPath: keyPath] = newValue
                appState.selectedPresetID = nil
            }
        )
    }

    private func slider(
        _ label: String, _ value: Binding<Float>, _ lowLabel: String, _ highLabel: String,
        range: ClosedRange<Float> = 0...1
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.subheadline.weight(.medium))
            Slider(value: value, in: range, onEditingChanged: { editing in
                if !editing { appState.previewClick() }
            })
            HStack {
                Text(lowLabel).font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text(highLabel).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}
