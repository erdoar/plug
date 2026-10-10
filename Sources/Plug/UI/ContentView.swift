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
                Text("Input: test tone, 440 Hz")
                    .foregroundStyle(.secondary)
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
