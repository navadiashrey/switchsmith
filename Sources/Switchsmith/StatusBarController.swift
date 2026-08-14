import Cocoa
import SwiftUI

final class StatusBarController: NSObject, NSWindowDelegate {
    private let statusItem: NSStatusItem
    private let appState: AppState
    private var designerWindow: NSWindow?

    init(appState: AppState) {
        self.appState = appState
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Switchsmith")
        }

        let menu = NSMenu()

        let titleItem = NSMenuItem(title: "Switchsmith", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(.separator())

        let enabledItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
        enabledItem.target = self
        enabledItem.state = appState.isEnabled ? .on : .off
        menu.addItem(enabledItem)
        self.enabledMenuItem = enabledItem

        let designerItem = NSMenuItem(title: "Switch Designer…", action: #selector(openDesigner), keyEquivalent: "d")
        designerItem.target = self
        menu.addItem(designerItem)

        menu.addItem(.separator())

        let presetsMenu = NSMenu()
        for preset in SwitchPresets.all {
            let item = NSMenuItem(title: preset.name, action: #selector(selectPreset(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = preset.id
            item.state = appState.selectedPresetID == preset.id ? .on : .off
            presetsMenu.addItem(item)
        }
        let presetsItem = NSMenuItem(title: "Preset", action: nil, keyEquivalent: "")
        presetsItem.submenu = presetsMenu
        menu.addItem(presetsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Switchsmith", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        self.menu = menu
    }

    private var menu: NSMenu?
    private var enabledMenuItem: NSMenuItem?

    @objc private func toggleEnabled() {
        appState.isEnabled.toggle()
        enabledMenuItem?.state = appState.isEnabled ? .on : .off
    }

    @objc private func selectPreset(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String,
              let preset = SwitchPresets.all.first(where: { $0.id == id }) else { return }
        appState.applyPreset(preset)
        appState.previewClick()
        if let presetsMenu = menu?.item(withTitle: "Preset")?.submenu {
            for item in presetsMenu.items {
                item.state = (item.representedObject as? String) == id ? .on : .off
            }
        }
    }

    @objc private func openDesigner() {
        if designerWindow == nil {
            let hosting = NSHostingController(rootView: DesignerView(appState: appState))
            let window = NSWindow(contentViewController: hosting)
            window.title = "Switch Designer"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.delegate = self
            designerWindow = window
        }
        NSApp.setActivationPolicy(.regular)
        designerWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
