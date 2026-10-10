/// Identifies an Audio Unit by its type, subtype and manufacturer
/// four-character codes, e.g. "aufx" / "dely" / "appl" for Apple's AUDelay.
public struct EffectID: Hashable {
    public let type: UInt32
    public let subtype: UInt32
    public let manufacturer: UInt32

    public init(type: UInt32, subtype: UInt32, manufacturer: UInt32) {
        self.type = type
        self.subtype = subtype
        self.manufacturer = manufacturer
    }

    /// Builds the codes from four-character strings. Nil unless each string is
    /// exactly four ASCII characters.
    public init?(type: String, subtype: String, manufacturer: String) {
        guard let type = Self.code(type),
              let subtype = Self.code(subtype),
              let manufacturer = Self.code(manufacturer) else { return nil }
        self.init(type: type, subtype: subtype, manufacturer: manufacturer)
    }

    private static func code(_ text: String) -> UInt32? {
        let bytes = Array(text.utf8)
        guard bytes.count == 4, bytes.allSatisfy({ $0 < 128 }) else { return nil }
        return bytes.reduce(0) { $0 << 8 | UInt32($1) }
    }
}

/// An installed effect as shown in the Add effect menu.
public struct EffectInfo: Identifiable, Hashable {
    public let id: EffectID
    public let name: String
    public let manufacturer: String

    public init(id: EffectID, name: String, manufacturer: String) {
        self.id = id
        self.name = name
        self.manufacturer = manufacturer
    }
}
