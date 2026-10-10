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
    /// App keys (see `AppKey`) captured when the input is `.apps`.
    public var capturedApps: [String]

    public init(input: InputSource, outputDeviceUID: String?, slots: [SavedSlot], capturedApps: [String] = []) {
        self.input = input
        self.outputDeviceUID = outputDeviceUID
        self.slots = slots
        self.capturedApps = capturedApps
    }

    /// Files saved before a field existed still load, with its default.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        input = try container.decode(InputSource.self, forKey: .input)
        outputDeviceUID = try container.decodeIfPresent(String.self, forKey: .outputDeviceUID)
        slots = try container.decode([SavedSlot].self, forKey: .slots)
        capturedApps = try container.decodeIfPresent([String].self, forKey: .capturedApps) ?? []
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
