import Combine
import Foundation
import PlugCore
import PlugEngine

/// Installed effects from one manufacturer, for the Add effect menu.
struct EffectGroup: Identifiable {
    let manufacturer: String
    let effects: [EffectInfo]
    var id: String { manufacturer }
}

/// App state shared by the UI. Holds the chain and the engine, and keeps the
/// engine's effects in step with the chain.
@MainActor
final class HostModel: ObservableObject {
    @Published private(set) var chain = PluginChain()
    @Published private(set) var isRunning = false
    @Published private(set) var outputDevices: [OutputDevice] = []
    @Published private(set) var selectedOutputID: UInt32?
    @Published private(set) var input: InputSource = .testTone
    @Published var errorMessage: String?
    let effectGroups: [EffectGroup]

    private let engine: AudioEngine

    init() {
        engine = AudioEngine()
        effectGroups = Dictionary(grouping: EffectCatalog.installedEffects(), by: \.manufacturer)
            .map { EffectGroup(manufacturer: $0.key, effects: $0.value) }
            .sorted { $0.manufacturer < $1.manufacturer }
        // The engine starts on the system default output.
        selectedOutputID = OutputDevices.defaultDeviceID()
        refreshOutputDevices()
    }

    func refreshOutputDevices() {
        outputDevices = OutputDevices.all()
    }

    func selectInput(_ source: InputSource) {
        do {
            try engine.setInput(source)
            input = source
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't switch input: \(error.localizedDescription)"
        }
        isRunning = engine.isRunning
    }

    func selectOutput(_ deviceID: UInt32) {
        do {
            try engine.setOutputDevice(deviceID)
            selectedOutputID = deviceID
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't switch output: \(error.localizedDescription)"
        }
        isRunning = engine.isRunning
    }

    func addEffect(_ effect: EffectInfo) {
        chain.append(PluginSlot(name: effect.name, effect: effect.id))
        syncEngine()
    }

    func removeSlot(id: UUID) {
        guard let index = chain.index(of: id) else { return }
        chain.remove(at: index)
        syncEngine()
    }

    func setBypassed(_ bypassed: Bool, slotID: UUID) {
        guard let index = chain.index(of: slotID) else { return }
        chain.setBypassed(bypassed, at: index)
        syncEngine()
    }

    func toggleEngine() {
        do {
            if engine.isRunning {
                engine.stop()
            } else {
                try engine.start()
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isRunning = engine.isRunning
    }

    private func syncEngine() {
        let slots = chain.slots
        Task {
            do {
                try await engine.setChain(slots)
                errorMessage = nil
            } catch {
                errorMessage = "Couldn't load effect: \(error.localizedDescription)"
            }
            isRunning = engine.isRunning
        }
    }
}
