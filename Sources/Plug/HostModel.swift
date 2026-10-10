import Combine
import Foundation
import PlugCore
import PlugEngine

/// App state shared by the UI. Holds the chain and the engine.
@MainActor
final class HostModel: ObservableObject {
    @Published private(set) var chain = PluginChain()
    @Published private(set) var isRunning = false
    @Published var errorMessage: String?

    private let engine = AudioEngine()

    func addPlaceholderSlot() {
        chain.append(PluginSlot(name: "Empty slot \(chain.slots.count + 1)"))
    }

    func removeSlot(at index: Int) {
        chain.remove(at: index)
    }

    func toggleBypass(at index: Int) {
        guard chain.slots.indices.contains(index) else { return }
        chain.setBypassed(!chain.slots[index].isBypassed, at: index)
    }

    func toggleEngine() {
        do {
            if isRunning {
                engine.stop()
            } else {
                try engine.start()
            }
            isRunning = engine.isRunning
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
