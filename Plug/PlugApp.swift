import SwiftUI

@main
struct PlugApp: App {
    @StateObject private var model = HostModel()

    var body: some Scene {
        WindowGroup("Plug") {
            ContentView(model: model)
        }
    }
}
