import CoreMIDI
import Foundation
import PlugCore

/// Listens to every MIDI source on the Mac (USB and Bluetooth controllers,
/// other apps through the IAC Driver), including sources that appear later,
/// and reports control changes on the main queue. Receive-only.
public final class MIDIInput {
    /// Called on the main queue.
    public var onControlChange: ((ControlChange) -> Void)?

    private var client = MIDIClientRef()
    private var port = MIDIPortRef()
    private var connected: Set<MIDIEndpointRef> = []

    public init() throws {
        try check(MIDIClientCreateWithBlock("Plug" as CFString, &client) { [weak self] notification in
            guard notification.pointee.messageID == .msgSetupChanged else { return }
            DispatchQueue.main.async { self?.connectSources() }
        }, "start MIDI")
        // MIDI arrives on CoreMIDI's own thread (not an audio thread), so
        // gathering words into an array here is fine.
        try check(MIDIInputPortCreateWithProtocol(client, "Plug input" as CFString, ._1_0, &port) { [weak self] events, _ in
            var words: [UInt32] = []
            for packet in events.unsafeSequence() {
                let count = Int(packet.pointee.wordCount)
                withUnsafeBytes(of: packet.pointee.words) { raw in
                    words.append(contentsOf: raw.bindMemory(to: UInt32.self).prefix(count))
                }
            }
            let changes = UMP.controlChanges(in: words)
            guard !changes.isEmpty else { return }
            DispatchQueue.main.async {
                changes.forEach { self?.onControlChange?($0) }
            }
        }, "open Plug's MIDI input")
        connectSources()
    }

    deinit {
        MIDIPortDispose(port)
        MIDIClientDispose(client)
    }

    private func connectSources() {
        for index in 0..<MIDIGetNumberOfSources() {
            let source = MIDIGetSource(index)
            guard source != 0, !connected.contains(source) else { continue }
            if MIDIPortConnectSource(port, source, nil) == noErr {
                connected.insert(source)
            }
        }
    }
}
