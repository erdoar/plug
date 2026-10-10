import Foundation

/// One effect slot in the chain. `effect` names the Audio Unit to load; a
/// slot without one is an empty placeholder and passes audio through.
public struct PluginSlot: Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public var effect: EffectID?
    public var isBypassed: Bool

    public init(name: String, effect: EffectID? = nil, isBypassed: Bool = false) {
        self.id = UUID()
        self.name = name
        self.effect = effect
        self.isBypassed = isBypassed
    }
}

/// The ordered effect chain between the input source and the output device.
/// Pure model: no CoreAudio here, so it can be tested without audio hardware.
public struct PluginChain: Equatable {
    public private(set) var slots: [PluginSlot] = []

    public init() {}

    public func index(of id: UUID) -> Int? {
        slots.firstIndex { $0.id == id }
    }

    public mutating func append(_ slot: PluginSlot) {
        slots.append(slot)
    }

    public mutating func remove(at index: Int) {
        guard slots.indices.contains(index) else { return }
        slots.remove(at: index)
    }

    public mutating func move(from source: Int, to destination: Int) {
        guard slots.indices.contains(source), (0...slots.count).contains(destination) else { return }
        let slot = slots.remove(at: source)
        let target = destination > source ? destination - 1 : destination
        slots.insert(slot, at: target)
    }

    /// Moves the slots at `source` so they sit before the slot that is
    /// currently at `destination` (or at the end when it equals the count),
    /// keeping their order. The same convention as SwiftUI's list `onMove`.
    public mutating func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        let moving = source.filter { slots.indices.contains($0) }
        guard !moving.isEmpty, (0...slots.count).contains(destination) else { return }
        let moved = moving.map { slots[$0] }
        let shift = moving.filter { $0 < destination }.count
        for index in moving.reversed() {
            slots.remove(at: index)
        }
        slots.insert(contentsOf: moved, at: destination - shift)
    }

    public mutating func setBypassed(_ bypassed: Bool, at index: Int) {
        guard slots.indices.contains(index) else { return }
        slots[index].isBypassed = bypassed
    }
}
