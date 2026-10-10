import Foundation

/// An effect slot as saved between launches. `state` is the Audio Unit's own
/// saved state (its parameters and any internal settings), as the unit
/// provides it; nil means the unit's defaults.
public struct SavedSlot: Codable, Equatable {
    public var name: String
    public var effect: EffectID
    public var isBypassed: Bool
    public var state: Data?

    public init(name: String, effect: EffectID, isBypassed: Bool, state: Data?) {
        self.name = name
        self.effect = effect
        self.isBypassed = isBypassed
        self.state = state
    }
}

/// Everything Plug restores on launch. The output device is stored by UID,
/// which stays the same across reconnects and restarts.
public struct HostSettings: Codable, Equatable {
    public var version = 1
    public var input: InputSource
    public var outputDeviceUID: String?
    public var slots: [SavedSlot]

    public init(input: InputSource, outputDeviceUID: String?, slots: [SavedSlot]) {
        self.input = input
        self.outputDeviceUID = outputDeviceUID
        self.slots = slots
    }
}

/// Reads and writes settings as JSON.
public enum SettingsStore {
    /// Nil if the file is missing or can't be read; Plug then starts fresh.
    public static func load(from url: URL) -> HostSettings? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(HostSettings.self, from: data)
    }

    public static func save(_ settings: HostSettings, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(settings).write(to: url, options: .atomic)
    }
}
