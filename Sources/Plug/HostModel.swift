import AppKit
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
    private let pluginWindows = PluginWindows()
    /// Saved effect states not yet put back into their units (they load
    /// asynchronously). Saving uses these until the unit has its own.
    private var pendingStates: [UUID: Data] = [:]
    private var terminationObserver: NSObjectProtocol?

    private static let settingsURL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Plug/settings.json")

    init() {
        engine = AudioEngine()
        effectGroups = Dictionary(grouping: EffectCatalog.installedEffects(), by: \.manufacturer)
            .map { EffectGroup(manufacturer: $0.key, effects: $0.value) }
            .sorted { $0.manufacturer < $1.manufacturer }
        // The engine starts on the system default output.
        selectedOutputID = OutputDevices.defaultDeviceID()
        refreshOutputDevices()
        restoreSettings()
        // Effect parameters change in their own windows without telling the
        // model, so save once more on the way out.
        terminationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.saveSettings() }
        }
    }

    /// Puts back the last session's input, output and effects. Never starts
    /// the engine: system audio capture waits for Start.
    private func restoreSettings() {
        guard let settings = SettingsStore.load(from: Self.settingsURL) else { return }
        // Effects first: choosing input and output below saves settings, and
        // that save must already include them.
        for saved in settings.slots {
            let slot = PluginSlot(name: saved.name, effect: saved.effect, isBypassed: saved.isBypassed)
            chain.append(slot)
            if let state = saved.state {
                pendingStates[slot.id] = state
            }
        }
        if let uid = settings.outputDeviceUID,
           let device = outputDevices.first(where: { $0.uid == uid }),
           device.id != selectedOutputID {
            selectOutput(device.id)
        }
        selectInput(settings.input)
        syncEngine()
        errorMessage = nil
    }

    func saveSettings() {
        let settings = HostSettings(
            input: input,
            outputDeviceUID: outputDevices.first { $0.id == selectedOutputID }?.uid,
            slots: chain.slots.compactMap { slot in
                slot.effect.map { effect in
                    SavedSlot(name: slot.name, effect: effect, isBypassed: slot.isBypassed,
                              state: engine.savedState(for: slot.id) ?? pendingStates[slot.id])
                }
            }
        )
        do {
            try SettingsStore.save(settings, to: Self.settingsURL)
        } catch {
            errorMessage = "Couldn't save settings: \(error.localizedDescription)"
        }
    }

    func refreshOutputDevices() {
        outputDevices = OutputDevices.all()
    }

    func selectInput(_ source: InputSource) {
        do {
            try engine.setInput(source)
            input = source
            errorMessage = nil
            saveSettings()
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
            saveSettings()
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
        pluginWindows.close(slotID: id)
        pendingStates[id] = nil
        syncEngine()
    }

    func openControls(slotID: UUID) {
        guard let index = chain.index(of: slotID),
              let unit = engine.audioUnit(for: slotID) else {
            errorMessage = "That effect hasn't finished loading yet."
            return
        }
        let title = chain.slots[index].name
        Task {
            await pluginWindows.open(unit, title: title, slotID: slotID)
        }
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
                for (slotID, state) in pendingStates where engine.audioUnit(for: slotID) != nil {
                    engine.restoreState(state, for: slotID)
                    pendingStates[slotID] = nil
                }
                errorMessage = nil
            } catch {
                errorMessage = "Couldn't load effect: \(error.localizedDescription)"
            }
            isRunning = engine.isRunning
            saveSettings()
        }
    }
}
