import AVFoundation
import PlugCore
import PlugRingBuffer

/// Owns the audio graph:
///
///     test tone ----------\
///                          input mixer -> effect chain -> main mixer -> output device
///     system audio tap ---/
///
/// The input mixer converts the capture's sample rate; the input switch just
/// sets which of its two inputs is audible. Output is the system default
/// until a device is chosen.
@MainActor
public final class AudioEngine {
    private let engine: AVAudioEngine
    private let format: AVAudioFormat
    private let inputMixer: AVAudioMixerNode
    private let tone: AVAudioSourceNode
    private let ring = CaptureRing()
    private var captureNode: AVAudioSourceNode?
    private var tap: SystemAudioTap?
    private var outputDeviceID: UInt32?
    private var units: [UUID: AVAudioUnit] = [:]
    private var loading: Set<UUID> = []
    private var desiredSlots: [PluginSlot] = []

    /// Slot IDs in the order their effects are wired after the input mixer.
    public private(set) var wiredSlotIDs: [UUID] = []

    public private(set) var input: InputSource = .testTone

    public var isRunning: Bool { engine.isRunning }

    public init() {
        let engine = AVAudioEngine()
        let outputRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        let format = AVAudioFormat(standardFormatWithSampleRate: outputRate > 0 ? outputRate : 48_000,
                                   channels: 2)!
        // 440 Hz at -20 dBFS: audible but not loud.
        let tone = SineOscillator(frequency: 440, amplitude: 0.1, sampleRate: format.sampleRate)
            .makeNode(format: format)
        let inputMixer = AVAudioMixerNode()
        engine.attach(inputMixer)
        engine.attach(tone)
        engine.connect(tone, to: inputMixer, fromBus: 0, toBus: 0, format: format)
        engine.connect(inputMixer, to: engine.mainMixerNode, fromBus: 0, toBus: 0, format: format)
        self.engine = engine
        self.format = format
        self.inputMixer = inputMixer
        self.tone = tone
    }

    /// Starts playing. With system audio as the input this also starts the
    /// capture, which mutes other apps at the speakers until `stop()`.
    public func start() throws {
        guard !engine.isRunning else { return }
        if input == .systemAudio {
            try startCapture()
        }
        do {
            try engine.start()
        } catch {
            stopCapture()
            throw error
        }
    }

    /// Stops playing and ends any capture, so other apps play normally again.
    public func stop() {
        engine.stop()
        stopCapture()
    }

    /// Chooses what goes into the effect chain. System audio is captured only
    /// while the engine runs.
    public func setInput(_ source: InputSource) throws {
        guard source != input else { return }
        switch source {
        case .testTone:
            stopCapture()
            tone.volume = 1
            captureNode?.volume = 0
        case .systemAudio:
            if engine.isRunning {
                try startCapture()
            }
            tone.volume = 0
            captureNode?.volume = 1
        }
        input = source
    }

    private func startCapture() throws {
        guard tap == nil else { return }
        let tap = try SystemAudioTap(ring: ring, clockDeviceUID: try clockDeviceUID())
        if captureNode == nil || captureNode?.outputFormat(forBus: 0).sampleRate != tap.sampleRate {
            let wasRunning = engine.isRunning
            if wasRunning { engine.stop() }
            if let old = captureNode {
                engine.detach(old)
            }
            let captureFormat = AVAudioFormat(standardFormatWithSampleRate: tap.sampleRate, channels: 2)!
            let node = Self.makeCaptureNode(ring: ring, format: captureFormat)
            engine.attach(node)
            engine.connect(node, to: inputMixer, fromBus: 0, toBus: 1, format: captureFormat)
            captureNode = node
            if wasRunning { try engine.start() }
        }
        self.tap = tap
    }

    private func stopCapture() {
        tap?.stop()
        tap = nil
    }

    private func clockDeviceUID() throws -> String {
        guard let id = outputDeviceID ?? OutputDevices.defaultDeviceID(),
              let device = OutputDevices.all().first(where: { $0.id == id }) else {
            throw CoreAudioError(action: "find the output device to capture alongside", status: noErr)
        }
        return device.uid
    }

    /// Plays whatever the capture ring holds. Runs on the render thread.
    nonisolated private static func makeCaptureNode(ring: CaptureRing, format: AVAudioFormat) -> AVAudioSourceNode {
        let ringPointer = ring.pointer
        return AVAudioSourceNode(format: format) { _, _, frameCount, bufferList in
            _ = ring
            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            guard let left = buffers.first?.mData?.assumingMemoryBound(to: Float.self) else { return noErr }
            let right = buffers.count > 1
                ? buffers[1].mData?.assumingMemoryBound(to: Float.self) ?? left
                : left
            plug_ring_read(ringPointer, left, right, frameCount)
            return noErr
        }
    }

    /// Sends the output to `deviceID`, restarting the engine if it was running.
    public func setOutputDevice(_ deviceID: UInt32) throws {
        let wasRunning = engine.isRunning
        if wasRunning { engine.stop() }
        try engine.outputNode.auAudioUnit.setDeviceID(deviceID)
        outputDeviceID = deviceID
        // Match the mixer's output to the new device's sample rate. The output
        // unit maps stereo onto the device's first two channels.
        let hardware = engine.outputNode.outputFormat(forBus: 0)
        if hardware.sampleRate > 0,
           let format = AVAudioFormat(standardFormatWithSampleRate: hardware.sampleRate,
                                      channels: min(max(hardware.channelCount, 1), 2)) {
            engine.connect(engine.mainMixerNode, to: engine.outputNode, format: format)
        }
        if wasRunning { try engine.start() }
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
        var previous: AVAudioNode = inputMixer
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
