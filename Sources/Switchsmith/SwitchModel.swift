import Foundation

/// The parameters of a synthesized switch. Unlike a sample pack, this
/// entirely *is* the sound — there is no recording behind it.
struct SwitchParameters: Equatable {
    /// Amount of high-frequency transient noise on impact. 0 = soft, dull tap. 1 = sharp, clacky snap.
    var sharpness: Float
    /// How much low-frequency body resonance the switch has. 0 = thin/light. 1 = heavy bottom-out thock.
    var weight: Float
    /// Tone color of the noise transient. 0 = muted/dark. 1 = bright/crisp.
    var brightness: Float
    /// Decay time of the resonant tail, in seconds.
    var decay: Float
    /// Per-keystroke random variation applied to pitch and tone, 0...1.
    var jitter: Float
    /// Overall output level, 0...1.
    var volume: Float

    static let `default` = SwitchParameters(
        sharpness: 0.55, weight: 0.55, brightness: 0.55, decay: 0.08, jitter: 0.25, volume: 0.8
    )
}

struct SwitchPreset: Identifiable, Equatable {
    let id: String
    let name: String
    let blurb: String
    let parameters: SwitchParameters
}

enum SwitchPresets {
    static let all: [SwitchPreset] = [
        SwitchPreset(
            id: "cream",
            name: "Cream",
            blurb: "Warm, rounded, a little muted",
            parameters: SwitchParameters(sharpness: 0.35, weight: 0.55, brightness: 0.40, decay: 0.09, jitter: 0.2, volume: 0.8)
        ),
        SwitchPreset(
            id: "box-jade",
            name: "Box Jade",
            blurb: "Sharp, clacky, high-pitched snap",
            parameters: SwitchParameters(sharpness: 0.9, weight: 0.35, brightness: 0.8, decay: 0.05, jitter: 0.3, volume: 0.8)
        ),
        SwitchPreset(
            id: "linear-red",
            name: "Linear Red",
            blurb: "Soft, quiet, minimal transient",
            parameters: SwitchParameters(sharpness: 0.2, weight: 0.55, brightness: 0.3, decay: 0.1, jitter: 0.15, volume: 0.7)
        ),
        SwitchPreset(
            id: "buckling-spring",
            name: "Buckling Spring",
            blurb: "Loud, heavy, springy — an office from 1987",
            parameters: SwitchParameters(sharpness: 0.7, weight: 0.85, brightness: 0.5, decay: 0.13, jitter: 0.25, volume: 0.9)
        ),
        SwitchPreset(
            id: "topre",
            name: "Topre",
            blurb: "Deep, muted, electrostatic thock",
            parameters: SwitchParameters(sharpness: 0.15, weight: 0.9, brightness: 0.25, decay: 0.15, jitter: 0.1, volume: 0.75)
        ),
    ]

    static let defaultPreset = all[0]
}
