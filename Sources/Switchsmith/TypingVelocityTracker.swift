import Foundation

/// Tracks the rolling interval between keystrokes and maps it to an
/// intensity multiplier — typing faster makes the synthesized clicks a
/// little louder and punchier, mirroring how a real switch feels under
/// a faster, more forceful cadence. Typing slowly settles back to a
/// calmer baseline.
final class TypingVelocityTracker {
    private var lastKeyDownTime: CFAbsoluteTime?
    private var averageInterval: Double = 0.2 // seconds, starts at a relaxed pace

    /// Call once per key-down. Returns an intensity multiplier to scale the click by.
    func recordKeyDownAndComputeIntensity() -> Float {
        let now = CFAbsoluteTimeGetCurrent()
        defer { lastKeyDownTime = now }

        guard let last = lastKeyDownTime else { return 1.0 }
        let interval = now - last
        // Ignore implausible gaps (e.g. resuming after minutes away) so one
        // pause doesn't skew the rolling average.
        guard interval > 0, interval < 2 else { return 1.0 }

        // Exponential moving average — recent typing rhythm matters more than old.
        averageInterval = averageInterval * 0.8 + interval * 0.2

        // ~60ms between keys (very fast) -> punchier. ~350ms+ (relaxed) -> baseline.
        let fastBound = 0.06
        let slowBound = 0.35
        let t = (averageInterval - fastBound) / (slowBound - fastBound)
        let clampedT = Double(max(0, min(1, t)))
        let intensity = 1.25 - clampedT * 0.35 // ranges ~0.90...1.25
        return Float(intensity)
    }
}
