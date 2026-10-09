import Foundation

/// One effect slot in the chain. The plugin reference is filled in when a
/// real Audio Unit is loaded; for now a slot is just a named placeholder.
struct PluginSlot: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var isBypassed = false
}

/// The ordered effect chain between the input source and the output device.
/// Pure model: no CoreAudio here, so it can be tested without audio hardware.
struct PluginChain: Equatable {
    private(set) var slots: [PluginSlot] = []

    mutating func append(_ slot: PluginSlot) {
        slots.append(slot)
    }

    mutating func remove(at index: Int) {
        guard slots.indices.contains(index) else { return }
        slots.remove(at: index)
    }

    mutating func move(from source: Int, to destination: Int) {
        guard slots.indices.contains(source), (0...slots.count).contains(destination) else { return }
        let slot = slots.remove(at: source)
        let target = destination > source ? destination - 1 : destination
        slots.insert(slot, at: target)
    }

    mutating func setBypassed(_ bypassed: Bool, at index: Int) {
        guard slots.indices.contains(index) else { return }
        slots[index].isBypassed = bypassed
    }
}
