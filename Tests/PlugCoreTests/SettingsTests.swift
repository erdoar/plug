import Foundation
import XCTest
@testable import PlugCore

final class SettingsTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("plug-settings-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testRoundTripCreatesFoldersAndKeepsEverything() throws {
        let delay = try XCTUnwrap(EffectID(type: "aufx", subtype: "dely", manufacturer: "appl"))
        let settings = HostSettings(
            input: .systemAudio,
            outputDeviceUID: "BuiltInSpeakerDevice",
            slots: [
                SavedSlot(name: "AUDelay", effect: delay, isBypassed: true, state: Data([1, 2, 3])),
                SavedSlot(name: "AUDelay", effect: delay, isBypassed: false, state: nil),
            ]
        )
        let url = directory.appendingPathComponent("nested/settings.json")
        try SettingsStore.save(settings, to: url)
        XCTAssertEqual(SettingsStore.load(from: url), settings)
    }

    func testCapturedAppsRoundTrip() throws {
        let settings = HostSettings(input: .apps, outputDeviceUID: nil, slots: [],
                                    capturedApps: ["com.spotify.client", "com.google.Chrome"])
        let url = directory.appendingPathComponent("settings.json")
        try SettingsStore.save(settings, to: url)
        XCTAssertEqual(SettingsStore.load(from: url), settings)
    }

    /// A file written before per-app capture existed still loads.
    func testOlderFileWithoutCapturedAppsLoads() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("settings.json")
        try Data(#"{"input":"systemAudio","slots":[],"version":1}"#.utf8).write(to: url)
        let loaded = try XCTUnwrap(SettingsStore.load(from: url))
        XCTAssertEqual(loaded.input, .systemAudio)
        XCTAssertNil(loaded.outputDeviceUID)
        XCTAssertEqual(loaded.capturedApps, [])
        XCTAssertEqual(loaded.masterVolume, 1)
        XCTAssertNil(loaded.masterMIDI)
    }

    func testMasterSettingsRoundTrip() throws {
        let settings = HostSettings(input: .testTone, outputDeviceUID: nil, slots: [],
                                    masterVolume: 0.42, masterMIDI: MIDIBinding(channel: 3, controller: 21))
        let url = directory.appendingPathComponent("settings.json")
        try SettingsStore.save(settings, to: url)
        XCTAssertEqual(SettingsStore.load(from: url), settings)
    }

    func testMissingFileLoadsAsNil() {
        XCTAssertNil(SettingsStore.load(from: directory.appendingPathComponent("absent.json")))
    }

    func testUnreadableFileLoadsAsNil() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("settings.json")
        try Data("not json".utf8).write(to: url)
        XCTAssertNil(SettingsStore.load(from: url))
    }
}
