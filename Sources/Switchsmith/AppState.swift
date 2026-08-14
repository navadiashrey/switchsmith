import Cocoa
import Combine

/// Central app state: owns the audio engine, the key monitor, and the
/// currently active switch parameters. Published so the SwiftUI Switch
/// Designer window can bind to it directly.
final class AppState: ObservableObject {
    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Keys.enabled) }
    }
    @Published var parameters: SwitchParameters {
        didSet {
            synth.parameters = parameters
            persistParameters()
        }
    }
    @Published var selectedPresetID: String? {
        didSet { UserDefaults.standard.set(selectedPresetID, forKey: Keys.presetID) }
    }

    private let synth = SynthEngine()
    private let keyMonitor = KeyMonitor()
    private let velocity = TypingVelocityTracker()

    private enum Keys {
        static let enabled = "switchsmith.enabled"
        static let presetID = "switchsmith.presetID"
        static let params = "switchsmith.parameters"
    }

    init() {
        let savedEnabled = UserDefaults.standard.object(forKey: Keys.enabled) as? Bool ?? true
        isEnabled = savedEnabled

        if let data = UserDefaults.standard.data(forKey: Keys.params),
           let decoded = try? JSONDecoder().decode(CodableParameters.self, from: data) {
            parameters = decoded.toParameters()
            selectedPresetID = UserDefaults.standard.string(forKey: Keys.presetID)
        } else {
            parameters = SwitchPresets.defaultPreset.parameters
            selectedPresetID = SwitchPresets.defaultPreset.id
        }

        synth.parameters = parameters
        synth.start()

        keyMonitor.onKeyDown = { [weak self] isRepeat in
            guard let self, self.isEnabled, !isRepeat else { return }
            let intensity = self.velocity.recordKeyDownAndComputeIntensity()
            self.synth.trigger(strength: intensity, isKeyUp: false)
        }
        keyMonitor.onKeyUp = { [weak self] in
            guard let self, self.isEnabled else { return }
            self.synth.trigger(strength: 1.0, isKeyUp: true)
        }
        keyMonitor.requestAccessibilityPermissionIfNeeded()
        keyMonitor.start()
    }

    func applyPreset(_ preset: SwitchPreset) {
        selectedPresetID = preset.id
        parameters = preset.parameters
    }

    /// Fires a single click through the current parameters — used by the
    /// Switch Designer's live preview so you can hear a slider change
    /// immediately without needing to type.
    func previewClick() {
        synth.trigger(strength: 1.0, isKeyUp: false)
    }

    private func persistParameters() {
        let codable = CodableParameters(from: parameters)
        if let data = try? JSONEncoder().encode(codable) {
            UserDefaults.standard.set(data, forKey: Keys.params)
        }
    }
}

/// `SwitchParameters` is a plain struct without Codable conformance in the
/// model file (kept free of persistence concerns); this mirrors it for storage.
private struct CodableParameters: Codable {
    var sharpness: Float
    var weight: Float
    var brightness: Float
    var decay: Float
    var jitter: Float
    var volume: Float

    init(from p: SwitchParameters) {
        sharpness = p.sharpness
        weight = p.weight
        brightness = p.brightness
        decay = p.decay
        jitter = p.jitter
        volume = p.volume
    }

    func toParameters() -> SwitchParameters {
        SwitchParameters(sharpness: sharpness, weight: weight, brightness: brightness, decay: decay, jitter: jitter, volume: volume)
    }
}
