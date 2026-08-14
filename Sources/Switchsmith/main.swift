import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var appState: AppState!
    private var statusBarController: StatusBarController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        appState = AppState()
        statusBarController = StatusBarController(appState: appState)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
