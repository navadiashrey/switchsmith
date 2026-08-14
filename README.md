# Switchsmith

A native macOS menu bar utility that gives your keyboard mechanical switch
sound — except there are no sound files. Every click is synthesized live,
in real time, from a small physically-inspired model, and you can shape the
model yourself instead of picking from a preset library.

## Why synthesis instead of samples

Existing tools in this space ([Klack](https://tryklack.com),
[Thock](https://github.com/kamillobinski/thock)) work by triggering
recorded `.wav`/`.caf` samples of real switches on every keystroke, with
pitch jitter layered on top for variation. That's a proven approach and it
sounds great, but it means the "sound" is fixed at recording time — you get
whichever switches someone recorded, and making a new one means recording
new audio.

Switchsmith takes a different angle: the click is generated from scratch,
per keystroke, by a small real-time DSP voice made of an impact transient
and a damped resonant body. Six parameters — sharpness, weight, brightness,
decay, jitter, volume — fully describe a switch's character, so "designing
a new switch" is dragging sliders and hearing the result instantly, not
sourcing a recording. The whole sound library ships as a few hundred bytes
of floating point numbers, not audio assets.

## Features

- **Real-time synthesis engine** — no bundled audio files at all
- **Switch Designer** — live sliders for sharpness, weight, brightness, decay, and jitter, with instant audio preview
- **Five built-in presets** (Cream, Box Jade, Linear Red, Buckling Spring, Topre) as starting points, each just a parameter set
- **Typing-velocity-reactive dynamics** — clicks get a little punchier as you type faster, and settle back down as you slow down
- **Distinct key-down / key-up character**, like a real switch's press and release
- **Menu bar only** — no dock icon, no window unless you open the designer

## How it works

**Global key capture.** A listen-only `CGEventTap` on `.cgSessionEventTap`
observes `keyDown`/`keyUp` system-wide (never modifies or blocks events).
This needs both **Accessibility** and **Input Monitoring** permission —
`CGEvent.tapCreate` returns `nil` outright if either is missing, which is a
much clearer signal than AppKit's `NSEvent` global monitor, which can
report success while silently never delivering events.

**Synthesis.** An `AVAudioSourceNode` render callback generates every
sample live — no `AVAudioPlayerNode`, no pre-rendered buffers. Each voice
is a plain value type in a fixed-size pool (24 voices), mutated in place
with no allocation or locking inside the per-sample hot path (a single
`NSLock` guards the pool itself, held for the whole render block rather
than per sample). Each click layers two components:

- an **impact transient** — a short lowpass-filtered noise burst, shaped
  by `sharpness` and `brightness`
- a **resonant body** — a very brief noise impulse excites a second-order
  bandpass (biquad) filter tuned by `weight`, whose output is independently
  amplitude-gated by `decay`

Driving the body with an *impulse* into a resonator, rather than a
sustained pure tone, is deliberate: the first version of this engine used
two additive sine oscillators for the body and it sounded like a bell being
struck, not a keyboard — pure tones ringing for hundreds of milliseconds
read as tonal/musical no matter how the envelope is shaped. Exciting a
damped resonator with a transient and gating it independently of the
filter's own decay gives a percussive thump instead, and keeps the `decay`
slider behaving predictably regardless of the filter's `Q`.

**Typing-velocity dynamics.** An exponential moving average of the interval
between consecutive key-downs maps to an intensity multiplier applied to
each new voice — a tightening cadence nudges volume/punch up, a relaxed
one settles it back to baseline.

**UI.** AppKit `NSStatusItem` for the menu bar chrome, SwiftUI for the
Switch Designer window, bridged with `NSHostingController`. State lives in
a single `ObservableObject` that both surfaces bind to directly.

## Requirements

macOS 13.5 (Ventura) or later.

## Installation

### Homebrew (recommended)

```sh
brew tap navadiashrey/switchsmith
brew install --cask switchsmith
```

> [!NOTE]
> Switchsmith is signed ad hoc (not notarized — that requires a paid Apple
> Developer Program membership). On first launch, right-click the app in
> Applications and choose **Open** once to bypass Gatekeeper's unidentified
> developer warning; after that it opens normally.

### Build from source

```sh
git clone https://github.com/navadiashrey/switchsmith.git
cd switchsmith
./make_app.sh
open Switchsmith.app
```

This produces `Switchsmith.app` via the Swift Package Manager — no Xcode
project required, just the Swift toolchain that ships with Xcode or the
Command Line Tools.

### Grant permissions

On first launch, macOS will prompt for **Accessibility**. You'll also need
to add Switchsmith manually under:

**System Settings → Privacy & Security → Input Monitoring**

Both are required for the global key monitor to receive events — see
[How it works](#how-it-works) above for why.

## Usage

Switchsmith lives in the menu bar (keyboard icon). Click it to enable/disable,
pick a preset, or open the **Switch Designer** to sculpt your own sound.
Your settings persist across launches.

## Project structure

```
Sources/Switchsmith/
├── main.swift                  # App entry point, NSApplicationDelegate
├── AppState.swift               # Central observable state, persistence
├── KeyMonitor.swift              # CGEventTap-based global key capture
├── SynthEngine.swift             # Real-time DSP voice engine
├── SwitchModel.swift              # Switch parameters + built-in presets
├── TypingVelocityTracker.swift     # Typing-speed → intensity mapping
├── StatusBarController.swift        # NSStatusItem menu bar UI
├── DesignerView.swift                # SwiftUI Switch Designer window
└── DebugLog.swift                     # Lightweight file logger
```

## License

MIT — see [LICENSE](LICENSE).
