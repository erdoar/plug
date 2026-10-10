import PlugCore
import SwiftUI

struct ContentView: View {
    @ObservedObject var model: HostModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(model.isRunning ? "Stop" : "Start") {
                    model.toggleEngine()
                }
                Picker("Input", selection: Binding(
                    get: { model.input },
                    set: { model.selectInput($0) }
                )) {
                    Text("Test tone (440 Hz)").tag(InputSource.testTone)
                    Text("System audio").tag(InputSource.systemAudio)
                }
                .fixedSize()
                Spacer()
                Menu("Add effect") {
                    if model.effectGroups.isEmpty {
                        Text("No Audio Unit effects found")
                    }
                    ForEach(model.effectGroups) { group in
                        Menu(group.manufacturer) {
                            ForEach(group.effects) { effect in
                                Button(effect.name) {
                                    model.addEffect(effect)
                                }
                            }
                        }
                    }
                }
                .fixedSize()
            }

            HStack {
                Picker("Output", selection: Binding(
                    get: { model.selectedOutputID ?? 0 },
                    set: { model.selectOutput($0) }
                )) {
                    ForEach(model.outputDevices) { device in
                        Text(device.name).tag(device.id)
                    }
                }
                Button {
                    model.refreshOutputDevices()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh the device list")
            }

            if model.input == .systemAudio {
                Text("While Plug runs, other apps play only through Plug. The first time, macOS asks to allow System Audio Recording. This needs the app built with scripts/bundle.sh.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            List {
                ForEach(model.chain.slots) { slot in
                    HStack {
                        Text(slot.name)
                        Spacer()
                        Toggle("Bypass", isOn: Binding(
                            get: { slot.isBypassed },
                            set: { model.setBypassed($0, slotID: slot.id) }
                        ))
                        Button {
                            model.removeSlot(id: slot.id)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .help("Remove effect")
                    }
                }
            }

            if let message = model.errorMessage {
                Text(message).foregroundStyle(.red)
            }
        }
        .padding()
        .frame(minWidth: 480, minHeight: 320)
    }
}
