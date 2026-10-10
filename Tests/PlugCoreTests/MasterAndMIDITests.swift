import Foundation
import XCTest
@testable import PlugCore

final class MasterVolumeTests: XCTestCase {
    func testSilenceUnityAndBoost() {
        XCTAssertEqual(MasterVolume.gain(forPosition: 0), 0)
        XCTAssertEqual(MasterVolume.gain(forPosition: MasterVolume.unityPosition), 1, accuracy: 0.0001)
        XCTAssertEqual(MasterVolume.gain(forPosition: 1), MasterVolume.maximumGain, accuracy: 0.0001)
        XCTAssertEqual(MasterVolume.maximumGain, 3.1623, accuracy: 0.0001, "+10 dB")
        XCTAssertEqual(MasterVolume.gain(forPosition: -3), 0, "clamped")
        XCTAssertEqual(MasterVolume.gain(forPosition: 4), MasterVolume.maximumGain, accuracy: 0.0001, "clamped")
    }

    func testRisesSteadily() {
        let gains = stride(from: 0.0, through: 1.0, by: 0.05).map { MasterVolume.gain(forPosition: $0) }
        XCTAssertEqual(gains, gains.sorted())
        XCTAssertEqual(Set(gains).count, gains.count)
    }

    func testLabels() {
        XCTAssertEqual(MasterVolume.label(forPosition: MasterVolume.unityPosition), "0.0 dB")
        XCTAssertEqual(MasterVolume.label(forPosition: 1), "+10.0 dB")
        XCTAssertEqual(MasterVolume.label(forPosition: 0.9), "+5.0 dB")
        XCTAssertEqual(MasterVolume.label(forPosition: 0), "-∞ dB")
        XCTAssertEqual(MasterVolume.label(forPosition: 0.4), "-18.1 dB")
    }
}

final class MIDITests: XCTestCase {
    func testReadsAControlChange() {
        // Type 2, group 0, status B0 (CC, channel 1), controller 7, value 64.
        XCTAssertEqual(UMP.controlChanges(in: [0x20B0_0740]),
                       [ControlChange(channel: 0, controller: 7, value: 64)])
    }

    func testIgnoresOtherMessagesAndStepsOverLongOnes() {
        let words: [UInt32] = [
            0x2090_3C7F,              // MIDI 1.0 note on: ignored
            0x4090_3C00, 0x7F00_0000, // MIDI 2.0 note on, two words: the second must not be read as a message
            0x20BF_0A10,              // CC 10 on channel 16, value 16
        ]
        XCTAssertEqual(UMP.controlChanges(in: words),
                       [ControlChange(channel: 15, controller: 10, value: 16)])
    }

    func testBindingMatchesOnlyItsChannelAndController() {
        let binding = MIDIBinding(channel: 0, controller: 7)
        XCTAssertTrue(binding.matches(ControlChange(channel: 0, controller: 7, value: 1)))
        XCTAssertFalse(binding.matches(ControlChange(channel: 1, controller: 7, value: 1)))
        XCTAssertFalse(binding.matches(ControlChange(channel: 0, controller: 8, value: 1)))
        XCTAssertEqual(binding.label, "CC 7 · CH 1")
    }
}
