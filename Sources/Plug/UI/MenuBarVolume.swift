import AppKit
import PlugCore
import SwiftUI

/// The panel under Plug's menu bar icon: a master volume slider, Start or
/// Stop, and ways back to the window or out of the app.
struct MenuBarVolume: View {
    @ObservedObject var model: HostModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Plug")
                    .font(.headline)
                Spacer()
                Text(model.isRunning ? "Playing" : "Stopped")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Image(systemName: "speaker.fill")
                    .foregroundStyle(.secondary)
                Slider(value: Binding(get: { model.masterPosition },
                                      set: { model.setMasterPosition($0) }),
                       in: 0...1,
                       onEditingChanged: { editing in
                           if !editing {
                               model.saveSettings()
                           }
                       })
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Master volume")
            HStack {
                Text("Master \(MasterVolume.label(forPosition: model.masterPosition))")
                    .monospacedDigit()
                Spacer()
                Button("0 dB") {
                    model.setMasterPosition(MasterVolume.unityPosition)
                    model.saveSettings()
                }
                .help("Return the master to 0 dB")
            }
            Divider()
            HStack {
                Button(model.isRunning ? "Stop" : "Start") {
                    model.toggleEngine()
                }
                Spacer()
                Button("Open Plug") {
                    NSApp.activate()
                    if !NSApp.windows.contains(where: { $0.isVisible && $0.canBecomeMain }) {
                        openWindow(id: "main")
                    }
                }
                Button("Quit") {
                    NSApp.terminate(nil)
                }
            }
        }
        .padding(14)
        .frame(width: 280)
    }
}
