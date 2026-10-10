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
                Spacer()
                Button("Add slot") {
                    model.addPlaceholderSlot()
                }
            }

            List {
                ForEach(Array(model.chain.slots.enumerated()), id: \.element.id) { index, slot in
                    HStack {
                        Text(slot.name)
                        Spacer()
                        Toggle("Bypass", isOn: Binding(
                            get: { slot.isBypassed },
                            set: { _ in model.toggleBypass(at: index) }
                        ))
                        .labelsHidden()
                    }
                }
                .onDelete { offsets in
                    offsets.sorted(by: >).forEach { model.removeSlot(at: $0) }
                }
            }

            if let message = model.errorMessage {
                Text(message).foregroundStyle(.red)
            }
        }
        .padding()
        .frame(minWidth: 420, minHeight: 300)
    }
}
