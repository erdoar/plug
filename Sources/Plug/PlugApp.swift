import AppKit
import SwiftUI

@main
struct PlugApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = HostModel()

    var body: some Scene {
        WindowGroup("Plug") {
            ContentView(model: model)
        }
    }
}

/// `swift run` starts the app without an .app bundle, so macOS treats it as a
/// background process. Make it a regular app so its window comes to the front
/// and takes keyboard input.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
    }
}
