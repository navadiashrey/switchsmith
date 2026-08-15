import Cocoa

/// Raw four-char-codes for the classic "get URL" Apple Event, spelled out
/// numerically rather than imported from Carbon to avoid depending on
/// exactly which Carbon submodule re-exports them on a given SDK.
/// Both the event class and event ID are 'GURL'; the direct-object
/// parameter keyword is '----'. These values are stable ABI, not
/// implementation details likely to change.
private let gurlEventClass: AEEventClass = 0x4755_524C // 'GURL'
private let gurlEventID: AEEventID = 0x4755_524C // 'GURL'
private let directObjectKeyword: AEKeyword = 0x2D2D_2D2D // '----'

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var appState: AppState!
    private var statusBarController: StatusBarController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        appState = AppState()
        statusBarController = StatusBarController(appState: appState)

        // Lets external tools (e.g. the Raycast extension) control the app
        // via switchsmith:// URLs without any persistent socket/server.
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURL(_:withReplyEvent:)),
            forEventClass: gurlEventClass,
            andEventID: gurlEventID
        )
    }

    @objc func handleGetURL(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: directObjectKeyword)?.stringValue,
              let url = URL(string: urlString) else { return }
        appState.handleControlURL(url)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
