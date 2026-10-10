import AVFoundation
import PlugCore

/// Owns the audio graph: test tone -> effect chain -> main mixer -> default
/// output device. App and system audio capture come later.
@MainActor
public final class AudioEngine {
    private let engine: AVAudioEngine
    private let format: AVAudioFormat
    private let tone: AVAudioSourceNode
    private var units: [UUID: AVAudioUnit] = [:]
    private var loading: Set<UUID> = []
    private var desiredSlots: [PluginSlot] = []

    /// Slot IDs in the order their effects are wired between tone and mixer.
    public private(set) var wiredSlotIDs: [UUID] = []

    public var isRunning: Bool { engine.isRunning }

    public init() {
        let engine = AVAudioEngine()
        let outputRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        let format = AVAudioFormat(standardFormatWithSampleRate: outputRate > 0 ? outputRate : 48_000,
                                   channels: 2)!
        // 440 Hz at -20 dBFS: audible but not loud.
        let tone = SineOscillator(frequency: 440, amplitude: 0.1, sampleRate: format.sampleRate)
            .makeNode(format: format)
        engine.attach(tone)
        engine.connect(tone, to: engine.mainMixerNode, fromBus: 0, toBus: 0, format: format)
        self.engine = engine
        self.format = format
        self.tone = tone
    }

    public func start() throws {
        guard !engine.isRunning else { return }
        try engine.start()
    }

    public func stop() {
        engine.stop()
    }

    /// Makes the graph match `slots`: loads Audio Units that aren't loaded
    /// yet, drops removed ones, rewires if the order changed, and applies
    /// bypass. Units already loaded are reused, so they keep their settings.
    public func setChain(_ slots: [PluginSlot]) async throws {
        desiredSlots = slots
        for slot in slots {
            guard let effect = slot.effect, units[slot.id] == nil, !loading.contains(slot.id) else { continue }
            loading.insert(slot.id)
            defer { loading.remove(slot.id) }
            units[slot.id] = try await AVAudioUnit.instantiate(with: effect.componentDescription, options: [])
        }
        try apply()
    }

    private func apply() throws {
        let wanted = Set(desiredSlots.map(\.id))
        var removed: [AVAudioUnit] = []
        for (id, unit) in units where !wanted.contains(id) {
            removed.append(unit)
            units[id] = nil
        }
        let order = desiredSlots.map(\.id).filter { units[$0] != nil }
        if order != wiredSlotIDs || !removed.isEmpty {
            try rewire(order, detaching: removed)
        }
        for slot in desiredSlots {
            units[slot.id]?.auAudioUnit.shouldBypassEffect = slot.isBypassed
        }
    }

    private func rewire(_ order: [UUID], detaching removed: [AVAudioUnit]) throws {
        let wasRunning = engine.isRunning
        if wasRunning { engine.stop() }
        for unit in removed where unit.engine != nil {
            engine.detach(unit)
        }
        // connect() breaks any earlier connection on the same output or input
        // bus, so reconnecting the whole path replaces the old one.
        var previous: AVAudioNode = tone
        for id in order {
            guard let unit = units[id] else { continue }
            if unit.engine == nil { engine.attach(unit) }
            engine.connect(previous, to: unit, fromBus: 0, toBus: 0, format: format)
            previous = unit
        }
        engine.connect(previous, to: engine.mainMixerNode, fromBus: 0, toBus: 0, format: format)
        wiredSlotIDs = order
        if wasRunning { try engine.start() }
    }
}
