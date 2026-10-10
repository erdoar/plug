import PlugCore
import PlugEngine
import XCTest

/// Uses Apple's built-in AUDelay, which ships with macOS. No sound is played:
/// the engine is wired but never started.
final class AudioEngineTests: XCTestCase {
    private static let delay = EffectID(type: "aufx", subtype: "dely", manufacturer: "appl")!

    func testCatalogListsAppleDelay() {
        XCTAssertTrue(EffectCatalog.installedEffects().contains { $0.id == Self.delay })
    }

    @MainActor
    func testChainLoadsReordersAndRemovesEffects() async throws {
        let engine = AudioEngine()
        let first = PluginSlot(name: "Delay 1", effect: Self.delay)
        let second = PluginSlot(name: "Delay 2", effect: Self.delay)

        try await engine.setChain([first, second])
        XCTAssertEqual(engine.wiredSlotIDs, [first.id, second.id])

        try await engine.setChain([second, first])
        XCTAssertEqual(engine.wiredSlotIDs, [second.id, first.id])

        try await engine.setChain([first])
        XCTAssertEqual(engine.wiredSlotIDs, [first.id])

        try await engine.setChain([])
        XCTAssertEqual(engine.wiredSlotIDs, [])
    }

    @MainActor
    func testEmptySlotsAreNotWired() async throws {
        let engine = AudioEngine()
        try await engine.setChain([PluginSlot(name: "Empty")])
        XCTAssertEqual(engine.wiredSlotIDs, [])
    }
}
