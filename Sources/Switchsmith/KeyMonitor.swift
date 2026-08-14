import Cocoa
import ApplicationServices

/// Listens for system-wide key up/down events via a low-level CGEventTap
/// (listen-only — never modifies or blocks events).
///
/// Requires both Accessibility and Input Monitoring permission (System
/// Settings > Privacy & Security). `CGEvent.tapCreate` returns nil outright
/// when either is missing, which is a far clearer signal than AppKit's
/// NSEvent global monitor, which can report success yet never actually
/// deliver events.
final class KeyMonitor {

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    var onKeyDown: ((_ isRepeat: Bool) -> Void)?
    var onKeyUp: (() -> Void)?

    /// Triggers the native macOS "wants to control this computer" prompt if not yet trusted.
    func requestAccessibilityPermissionIfNeeded() {
        let options: [String: Any] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        DebugLog.write("AXIsProcessTrustedWithOptions(prompt) -> \(trusted)")
    }

    func start() {
        guard eventTap == nil else { return }
        DebugLog.write("starting CGEventTap, AXIsProcessTrusted=\(AXIsProcessTrusted())")

        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, type, event, refcon in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<KeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
                if type == .keyDown {
                    let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
                    monitor.onKeyDown?(isRepeat)
                } else if type == .keyUp {
                    monitor.onKeyUp?()
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: refcon
        ) else {
            DebugLog.write("CGEvent.tapCreate returned nil — Accessibility/Input Monitoring permission not granted")
            return
        }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        DebugLog.write("CGEventTap created and enabled")
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }
}
