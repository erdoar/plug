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
        XCTAssertNotNil(engine.audioUnit(for: first.id))
        XCTAssertNil(engine.audioUnit(for: UUID()))

        try await engine.setChain([second, first])
        XCTAssertEqual(engine.wiredSlotIDs, [second.id, first.id])

        try await engine.setChain([first])
        XCTAssertEqual(engine.wiredSlotIDs, [first.id])

        try await engine.setChain([])
        XCTAssertEqual(engine.wiredSlotIDs, [])
        XCTAssertNil(engine.audioUnit(for: first.id))
    }

    /// Choosing system audio only records the choice; capture (and the
    /// permission prompt) starts with the engine, which this never starts.
    @MainActor
    func testSwitchingInputWithoutStartingDoesNotCapture() throws {
        let engine = AudioEngine()
        try engine.setInput(.systemAudio)
        XCTAssertEqual(engine.input, .systemAudio)
        XCTAssertFalse(engine.isRunning)
        try engine.setInput(.testTone)
        XCTAssertEqual(engine.input, .testTone)
    }

    /// Saved state carries parameter values from one unit to a fresh one.
    @MainActor
    func testSavedStateRestoresParameters() async throws {
        let original = AudioEngine()
        let slot = PluginSlot(name: "Delay", effect: Self.delay)
        try await original.setChain([slot])
        let unit = try XCTUnwrap(original.audioUnit(for: slot.id))
        let parameter = try XCTUnwrap(unit.auAudioUnit.parameterTree?.allParameters.first)
        let changed = parameter.minValue + (parameter.maxValue - parameter.minValue) * 0.37
        parameter.value = changed
        let state = try XCTUnwrap(original.savedState(for: slot.id))

        let restored = AudioEngine()
        let copy = PluginSlot(name: "Delay", effect: Self.delay)
        try await restored.setChain([copy])
        restored.restoreState(state, for: copy.id)
        let restoredUnit = try XCTUnwrap(restored.audioUnit(for: copy.id))
        let restoredParameter = try XCTUnwrap(restoredUnit.auAudioUnit.parameterTree?.parameter(withAddress: parameter.address))
        XCTAssertEqual(restoredParameter.value, changed, accuracy: 0.001)
    }

    func testProcessListLeavesOutPlug() {
        XCTAssertFalse(AudioProcesses.all().contains { $0.pid == getpid() })
    }

    @MainActor
    func testChoosingAppsWithoutStartingDoesNotCapture() throws {
        let engine = AudioEngine()
        try engine.setCapturedApps(["com.example.not-running"])
        try engine.setInput(.apps)
        XCTAssertEqual(engine.input, .apps)
        XCTAssertEqual(engine.capturedApps, ["com.example.not-running"])
        XCTAssertFalse(engine.isRunning)
    }

    @MainActor
    func testMasterGainCutsBoostsAndClamps() {
        let engine = AudioEngine()
        engine.masterGain = 0.25
        XCTAssertEqual(engine.masterGain, 0.25, accuracy: 0.0001)
        engine.masterGain = 3
        XCTAssertEqual(engine.masterGain, 3, accuracy: 0.0001)
        engine.masterGain = 10
        XCTAssertEqual(engine.masterGain, AudioEngine.maximumMasterGain, accuracy: 0.0001)
        XCTAssertEqual(AudioEngine.maximumMasterGain, MasterVolume.maximumGain, accuracy: 0.0001,
                       "the engine allows exactly the knob's +10 dB")
        engine.masterGain = 0
        XCTAssertEqual(engine.masterGain, 0)
    }

    func testMIDIInputStarts() throws {
        XCTAssertNoThrow(try MIDIInput())
    }

    @MainActor
    func testEmptySlotsAreNotWired() async throws {
        let engine = AudioEngine()
        try await engine.setChain([PluginSlot(name: "Empty")])
        XCTAssertEqual(engine.wiredSlotIDs, [])
    }
}

/// Reads real devices but plays nothing: the engine is never started.
final class OutputDeviceTests: XCTestCase {
    func testDefaultOutputIsListed() throws {
        let defaultID = try XCTUnwrap(OutputDevices.defaultDeviceID(), "This Mac has no default output device")
        XCTAssertTrue(OutputDevices.all().contains { $0.id == defaultID })
    }

    @MainActor
    func testSwitchingToDefaultOutputSucceeds() throws {
        let defaultID = try XCTUnwrap(OutputDevices.defaultDeviceID(), "This Mac has no default output device")
        let engine = AudioEngine()
        XCTAssertNoThrow(try engine.setOutputDevice(defaultID))
        XCTAssertFalse(engine.isRunning)
    }
}
