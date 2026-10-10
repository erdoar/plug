/// A MIDI 1.0 control change, as sent by a controller's knob or fader.
public struct ControlChange: Equatable {
    /// 0...15 (shown to people as 1...16).
    public let channel: UInt8
    public let controller: UInt8
    /// 0...127.
    public let value: UInt8

    public init(channel: UInt8, controller: UInt8, value: UInt8) {
        self.channel = channel
        self.controller = controller
        self.value = value
    }
}

/// The controller learned for the master knob.
public struct MIDIBinding: Codable, Equatable {
    public let channel: UInt8
    public let controller: UInt8

    public init(channel: UInt8, controller: UInt8) {
        self.channel = channel
        self.controller = controller
    }

    public func matches(_ change: ControlChange) -> Bool {
        change.channel == channel && change.controller == controller
    }

    /// "CC 7 · CH 1".
    public var label: String { "CC \(controller) · CH \(Int(channel) + 1)" }
}

/// Reads Universal MIDI Packets (the form CoreMIDI delivers), keeping only
/// MIDI 1.0 control changes. Messages are 1 to 4 words long depending on
/// their type, so the reader steps over each whole message.
public enum UMP {
    public static func wordCount(forMessageType type: UInt32) -> Int {
        switch type {
        case 0x0, 0x1, 0x2, 0x6, 0x7: return 1
        case 0x3, 0x4, 0x8, 0x9, 0xA: return 2
        case 0xB, 0xC: return 3
        default: return 4
        }
    }

    public static func controlChanges(in words: [UInt32]) -> [ControlChange] {
        var changes: [ControlChange] = []
        var index = 0
        while index < words.count {
            let word = words[index]
            let type = word >> 28
            // MIDI 1.0 channel voice message: type 2, status 0xBn = control change.
            if type == 0x2, (word >> 20) & 0xF == 0xB {
                changes.append(ControlChange(channel: UInt8((word >> 16) & 0xF),
                                             controller: UInt8((word >> 8) & 0x7F),
                                             value: UInt8(word & 0x7F)))
            }
            index += wordCount(forMessageType: type)
        }
        return changes
    }
}
