import Foundation
import XCTest
@testable import PlugCore

final class PresetTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("plug-presets-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testNamesAreCleaned() {
        XCTAssertEqual(PresetStore.cleanedName("  Late night  "), "Late night")
        XCTAssertEqual(PresetStore.cleanedName("Mix/Master:2"), "Mix-Master-2")
        XCTAssertEqual(PresetStore.cleanedName("../escape"), "-escape")
        XCTAssertEqual(PresetStore.cleanedName("..hidden"), "hidden")
        XCTAssertNil(PresetStore.cleanedName("   "))
        XCTAssertNil(PresetStore.cleanedName("..."))
    }

    func testSaveListLoadAndDelete() throws {
        let delay = try XCTUnwrap(EffectID(type: "aufx", subtype: "dely", manufacturer: "appl"))
        let evening = HostSettings(input: .systemAudio, outputDeviceUID: "Speakers",
                                   slots: [SavedSlot(name: "AUDelay", effect: delay, isBypassed: false, state: Data([9]))],
                                   masterPosition: 0.6)
        let podcast = HostSettings(input: .apps, outputDeviceUID: nil, slots: [], capturedApps: ["com.apple.Music"])

        XCTAssertEqual(PresetStore.names(in: directory), [], "no folder yet")
        XCTAssertEqual(try PresetStore.save(evening, named: " evening ", in: directory), "evening")
        try PresetStore.save(podcast, named: "Podcast", in: directory)
        try Data("not a preset".utf8).write(to: directory.appendingPathComponent("notes.txt"))

        XCTAssertEqual(PresetStore.names(in: directory), ["evening", "Podcast"])
        XCTAssertEqual(PresetStore.load(named: "evening", in: directory), evening)
        XCTAssertEqual(PresetStore.load(named: "Podcast", in: directory), podcast)
        XCTAssertNil(PresetStore.load(named: "missing", in: directory))

        try PresetStore.save(podcast, named: "evening", in: directory)
        XCTAssertEqual(PresetStore.load(named: "evening", in: directory), podcast, "saving again replaces")

        try PresetStore.delete(named: "evening", in: directory)
        XCTAssertEqual(PresetStore.names(in: directory), ["Podcast"])
    }

    func testEmptyNameIsRefused() {
        let settings = HostSettings(input: .testTone, outputDeviceUID: nil, slots: [])
        XCTAssertThrowsError(try PresetStore.save(settings, named: "  ", in: directory))
    }
}
