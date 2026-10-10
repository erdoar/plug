import AppKit
import PlugCore
import SwiftUI

@main
struct PlugApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("Plug", id: "main") {
            ContentView(model: appDelegate.model)
        }
        // The window follows the content, so it grows and shrinks with the drawer.
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuBarVolume(model: appDelegate.model)
        } label: {
            Image(nsImage: MenuBarIcon.image)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Owns the app's one model, so the window, the menu bar volume and the Dock
/// menu all work on the same state.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Created on first use (the window's first appearance), on the main thread.
    private(set) lazy var model = HostModel()

    /// Master levels offered in the Dock menu, in dB; nil is mute.
    private static let dockLevels: [Double?] = [10, 6, 3, 0, -3, -6, -12, -24, nil]

    /// `swift run` starts the app without an .app bundle, so macOS treats it
    /// as a background process. Make it a regular app so its window comes to
    /// the front and takes keyboard input.
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
    }

    /// Right-clicking the Dock icon: Start or Stop, then the master level in
    /// steps, with the nearest step ticked. (The Dock shows menu items only,
    /// not sliders; the slider lives in the menu bar.)
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        let transport = NSMenuItem(title: model.isRunning ? "Stop" : "Start",
                                   action: #selector(toggleRunning), keyEquivalent: "")
        transport.target = self
        menu.addItem(transport)
        menu.addItem(.separator())

        let heading = NSMenuItem(title: "Master: \(MasterVolume.label(forPosition: model.masterPosition))",
                                 action: nil, keyEquivalent: "")
        heading.isEnabled = false
        menu.addItem(heading)
        let current = MasterVolume.decibels(forPosition: model.masterPosition)
        for level in Self.dockLevels {
            let title = level.map { $0 == 0 ? "0 dB" : String(format: "%+.0f dB", $0) } ?? "Mute"
            let item = NSMenuItem(title: title, action: #selector(setMasterLevel(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = MasterVolume.position(forDecibels: level)
            switch (level, current) {
            case (nil, nil):
                item.state = .on
            case let (level?, current?) where abs(level - current) < 0.5:
                item.state = .on
            default:
                break
            }
            menu.addItem(item)
        }
        return menu
    }

    @objc private func toggleRunning() {
        model.toggleEngine()
    }

    @objc private func setMasterLevel(_ sender: NSMenuItem) {
        guard let position = sender.representedObject as? Double else { return }
        model.setMasterPosition(position)
        model.saveSettings()
    }
}
