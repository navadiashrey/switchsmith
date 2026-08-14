import AVFoundation

/// A tiny, self-contained, seedable noise generator. Plain xorshift —
/// cheap enough to call once per sample per voice on the real-time
/// audio thread with no allocation and no locking.
private struct FastRNG {
    var state: UInt32
    mutating func nextUnit() -> Float {
        state ^= state << 13
        state ^= state >> 17
        state ^= state << 5
        // Map to [-1, 1].
        return Float(state % 2_000_001) / 1_000_000.0 - 1.0
    }
}

/// One in-flight synthesized click. A plain value type mutated in place
/// inside a fixed-size pool — no allocation on the audio render thread.
///
/// The body isn't a pure tone (that reads as a bell/tuning fork, not a
/// keyboard switch): a short noise impulse excites a resonant bandpass
/// filter, which is then gated by its own short amplitude envelope. That's
/// the standard trick for a damped percussive thump instead of a ringing note.
private struct Voice {
    var active = false
    var age: Int = 0
    var lifetimeSamples: Int = 0

    // High-frequency impact transient (the "snap").
    var noiseEnv: Float = 0
    var noiseEnvMul: Float = 0
    var lpState: Float = 0
    var lpAlpha: Float = 0
    var noiseMix: Float = 0

    // Resonant body (the "thock") — noise-excited bandpass, amplitude-gated.
    var excitationEnv: Float = 0
    var excitationEnvMul: Float = 0
    var bodyEnv: Float = 0
    var bodyEnvMul: Float = 0
    var bodyMix: Float = 0
    var bqB0: Float = 0
    var bqB2: Float = 0
    var bqA1: Float = 0
    var bqA2: Float = 0
    var bqX1: Float = 0
    var bqX2: Float = 0
    var bqY1: Float = 0
    var bqY2: Float = 0

    var amplitude: Float = 0

    var rng = FastRNG(state: 0x9E3779B9)
}

/// Synthesizes every keystroke click live from a small physically-inspired
/// model (impact noise burst + damped resonant-body thump) instead of playing
/// back a recorded sample. Nothing in this app is an audio file — the
/// entire "sound library" is these parameters.
final class SynthEngine {

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private let sampleRate: Double = 44_100

    private let voiceLock = NSLock()
    private var voices = [Voice](repeating: Voice(), count: 24)
    private var nextVoiceIndex = 0
    private var rngSeed: UInt32 = 0x1234_5678

    var parameters: SwitchParameters = .default

    func start() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        let node = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList in
            guard let self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)

            self.voiceLock.lock()
            for frame in 0..<Int(frameCount) {
                var sample: Float = 0
                for i in 0..<self.voices.count {
                    guard self.voices[i].active else { continue }
                    sample += self.renderVoiceSample(index: i)
                }
                sample = max(-1, min(1, sample))
                for buffer in ablPointer {
                    let buf = UnsafeMutableBufferPointer<Float>(buffer)
                    if frame < buf.count { buf[frame] = sample }
                }
            }
            self.voiceLock.unlock()
            return noErr
        }

        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        sourceNode = node

        do {
            try engine.start()
            DebugLog.write("SynthEngine started, sampleRate=\(sampleRate)")
        } catch {
            DebugLog.write("SynthEngine failed to start: \(error)")
        }
    }

    /// Advances one voice by one sample and returns its contribution.
    /// Must be called with `voiceLock` held.
    private func renderVoiceSample(index i: Int) -> Float {
        var v = voices[i]
        defer { voices[i] = v }

        v.age += 1
        if v.age >= v.lifetimeSamples || v.noiseEnv + v.bodyEnv < 0.0003 {
            v.active = false
            return 0
        }

        // Impact transient: lowpassed noise burst.
        v.noiseEnv *= v.noiseEnvMul
        let noiseRaw = v.rng.nextUnit()
        v.lpState += v.lpAlpha * (noiseRaw - v.lpState)
        let noiseComponent = v.lpState * v.noiseEnv * v.noiseMix

        // Resonant body: brief noise impulse excites a bandpass filter,
        // whose output is separately amplitude-gated so it can't ring
        // on indefinitely regardless of filter Q.
        v.excitationEnv *= v.excitationEnvMul
        let excitation = v.rng.nextUnit() * v.excitationEnv
        let bqOut = v.bqB0 * excitation + v.bqB2 * v.bqX2 - v.bqA1 * v.bqY1 - v.bqA2 * v.bqY2
        v.bqX2 = v.bqX1
        v.bqX1 = excitation
        v.bqY2 = v.bqY1
        v.bqY1 = bqOut

        v.bodyEnv *= v.bodyEnvMul
        let bodyComponent = bqOut * v.bodyEnv * v.bodyMix

        return (noiseComponent + bodyComponent) * v.amplitude
    }

    /// Triggers a new synthesized click. Safe to call from any thread (typically the
    /// CGEventTap callback thread). `strength` scales amplitude — used both for the
    /// down/up asymmetry and for typing-velocity-reactive dynamics.
    func trigger(strength: Float, isKeyUp: Bool) {
        let p = parameters
        rngSeed = rngSeed &* 1_664_525 &+ 1_013_904_223
        var localRNG = FastRNG(state: rngSeed)

        let jitterAmount = p.jitter
        let freqJitter = 1 + localRNG.nextUnit() * 0.15 * jitterAmount

        // Heavier switches resonate lower; lighter switches resonate higher.
        let centerFreq = (2000 - p.weight * 1400) * freqJitter
        // Kept modest on purpose: high Q here is what makes a resonator
        // sound like a bell instead of a thump.
        let q: Float = 1.0 + p.weight * 1.3

        let releaseFactor: Float = isKeyUp ? 0.55 : 1.0
        let decay = p.decay * (isKeyUp ? 0.6 : 1.0)

        var voice = Voice()
        voice.active = true
        voice.age = 0

        // exp(-1/tau) per-sample multiplier so envelopes decay smoothly
        // without calling expf() every sample.
        let noiseTauSamples = max(1, 0.006 * Float(sampleRate))
        voice.noiseEnv = 1
        voice.noiseEnvMul = expf(-1 / noiseTauSamples)
        voice.lpAlpha = max(0.02, min(1, 0.05 + p.brightness * 0.8))
        voice.noiseMix = (0.25 + p.sharpness * 0.75) * releaseFactor

        // The excitation is a very brief impulse — it just "hits" the resonator once.
        let excitationTauSamples = max(1, 0.0015 * Float(sampleRate))
        voice.excitationEnv = 1
        voice.excitationEnvMul = expf(-1 / excitationTauSamples)

        // The body's own amplitude envelope, independent of filter Q, so the
        // Decay slider always behaves predictably.
        let bodyTauSamples = max(1, decay * 0.3 * Float(sampleRate))
        voice.bodyEnv = 1
        voice.bodyEnvMul = expf(-1 / bodyTauSamples)
        voice.bodyMix = (0.3 + p.weight * 0.9) * releaseFactor

        let w0 = Float(2 * Double.pi) * centerFreq / Float(sampleRate)
        let alpha = sinf(w0) / (2 * q)
        let cosw0 = cosf(w0)
        let a0 = 1 + alpha
        voice.bqB0 = alpha / a0
        voice.bqB2 = -alpha / a0
        voice.bqA1 = (-2 * cosw0) / a0
        voice.bqA2 = (1 - alpha) / a0

        voice.lifetimeSamples = Int(bodyTauSamples * 6) + 512
        voice.amplitude = p.volume * strength
        voice.rng = FastRNG(state: rngSeed | 1)

        voiceLock.lock()
        voices[nextVoiceIndex] = voice
        nextVoiceIndex = (nextVoiceIndex + 1) % voices.count
        voiceLock.unlock()
    }
}
