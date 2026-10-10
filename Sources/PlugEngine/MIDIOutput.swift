import CoreMIDI
import Foundation
import PlugCore

/// Sends MIDI from Plug's buttons to the Mac's MIDI outputs: hardware,
/// network sessions, and other apps through the IAC Driver.
public final class MIDIOutput {
    private var client = MIDIClientRef()
    private var port = MIDIPortRef()

    public init() throws {
        try check(MIDIClientCreateWithBlock("Plug buttons" as CFString, &client, nil), "start MIDI")
        try check(MIDIOutputPortCreate(client, "Plug output" as CFString, &port), "open Plug's MIDI output")
    }

    deinit {
        MIDIPortDispose(port)
        MIDIClientDispose(client)
    }

    /// The display names of the MIDI outputs on the Mac, for choosing one.
    public static func destinationNames() -> [String] {
        (0..<MIDIGetNumberOfDestinations()).compactMap { name(of: MIDIGetDestination($0)) }
    }

    /// Sends to the output with the message's destination name, or to every
    /// output when it has none. Returns false if a named output isn't there.
    @discardableResult
    public func send(_ message: MIDIMessage) -> Bool {
        let destinations = (0..<MIDIGetNumberOfDestinations())
            .map { MIDIGetDestination($0) }
            .filter { $0 != 0 && (message.destination == nil || Self.name(of: $0) == message.destination) }
        guard !destinations.isEmpty else { return message.destination == nil }
        let words = message.words
        // A note's on and off go out as separate lists, the off a moment later.
        for (index, word) in words.enumerated() {
            let delay = index == 0 ? 0 : 0.15
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
                for destination in destinations {
                    sendWord(word, to: destination)
                }
            }
        }
        return true
    }

    private func sendWord(_ word: UInt32, to destination: MIDIEndpointRef) {
        var list = MIDIEventList()
        var word = word
        withUnsafeMutablePointer(to: &list) { listPointer in
            let packet = MIDIEventListInit(listPointer, ._1_0)
            _ = MIDIEventListAdd(listPointer, MemoryLayout<MIDIEventList>.size, packet, 0, 1, &word)
            _ = MIDISendEventList(port, destination, listPointer)
        }
    }

    private static func name(of endpoint: MIDIEndpointRef) -> String? {
        var name: Unmanaged<CFString>?
        guard endpoint != 0,
              MIDIObjectGetStringProperty(endpoint, kMIDIPropertyDisplayName, &name) == noErr,
              let name else { return nil }
        return name.takeRetainedValue() as String
    }
}
