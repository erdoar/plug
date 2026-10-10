import CoreAudio
import Foundation
import PlugRingBuffer

/// Captures everything the Mac plays, except Plug itself, through a Core
/// Audio process tap. The tap mutes what it captures at the speakers, so the
/// only copy heard is the one Plug plays after its effects. Captured audio
/// arrives on a Core Audio I/O thread and goes into the capture ring.
///
/// Creating one starts capturing; `stop()` or deinit ends it and unmutes.
/// macOS asks for System Audio Recording permission the first time, which
/// needs the app bundle (scripts/bundle.sh).
final class SystemAudioTap {
    private(set) var sampleRate: Double = 0
    private var tapID = AudioObjectID(kAudioObjectUnknown)
    private var aggregateID = AudioObjectID(kAudioObjectUnknown)
    private var ioProcID: AudioDeviceIOProcID?

    /// `clockDeviceUID` is the output device whose clock the capture follows;
    /// use the device Plug plays to, so the two stay in step.
    init(ring: CaptureRing, clockDeviceUID: String) throws {
        let description = CATapDescription(
            stereoGlobalTapButExcludeProcesses: [try Self.ownProcessObject()]
        )
        description.name = "Plug"
        description.muteBehavior = .muted

        var tap = AudioObjectID(kAudioObjectUnknown)
        try check(AudioHardwareCreateProcessTap(description, &tap), "create the system audio tap")
        tapID = tap

        var format = AudioStreamBasicDescription()
        var formatSize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        var formatAddress = AudioObjectPropertyAddress(mSelector: kAudioTapPropertyFormat,
                                                       mScope: kAudioObjectPropertyScopeGlobal,
                                                       mElement: kAudioObjectPropertyElementMain)
        try check(AudioObjectGetPropertyData(tapID, &formatAddress, 0, nil, &formatSize, &format),
                  "read the system audio format")
        guard format.mFormatID == kAudioFormatLinearPCM,
              format.mFormatFlags & kAudioFormatFlagIsFloat != 0,
              format.mBitsPerChannel == 32 else {
            throw CoreAudioError(action: "use the system audio format (expected 32-bit float)", status: noErr)
        }
        sampleRate = format.mSampleRate

        // The tap is read through a private aggregate device clocked by the
        // output device.
        let aggregate: [String: Any] = [
            kAudioAggregateDeviceNameKey: "Plug Capture",
            kAudioAggregateDeviceUIDKey: "plug.capture.\(UUID().uuidString)",
            kAudioAggregateDeviceMainSubDeviceKey: clockDeviceUID,
            kAudioAggregateDeviceIsPrivateKey: true,
            kAudioAggregateDeviceIsStackedKey: false,
            kAudioAggregateDeviceTapAutoStartKey: true,
            kAudioAggregateDeviceSubDeviceListKey: [[kAudioSubDeviceUIDKey: clockDeviceUID]],
            kAudioAggregateDeviceTapListKey: [[
                kAudioSubTapDriftCompensationKey: true,
                kAudioSubTapUIDKey: description.uuid.uuidString,
            ]],
        ]
        var aggregateDevice = AudioObjectID(kAudioObjectUnknown)
        try check(AudioHardwareCreateAggregateDevice(aggregate as CFDictionary, &aggregateDevice),
                  "create the capture device")
        aggregateID = aggregateDevice

        let ringPointer = ring.pointer
        var procID: AudioDeviceIOProcID?
        try check(AudioDeviceCreateIOProcIDWithBlock(&procID, aggregateID, nil) { _, input, _, output, _ in
            _ = ring
            Self.write(UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: input)), to: ringPointer)
            // Plug plays through its own engine; this device's output stays silent.
            for buffer in UnsafeMutableAudioBufferListPointer(output) {
                if let data = buffer.mData {
                    memset(data, 0, Int(buffer.mDataByteSize))
                }
            }
        }, "set up audio capture")
        ioProcID = procID
        try check(AudioDeviceStart(aggregateID, procID), "start audio capture")
    }

    deinit {
        stop()
    }

    func stop() {
        if let procID = ioProcID {
            AudioDeviceStop(aggregateID, procID)
            AudioDeviceDestroyIOProcID(aggregateID, procID)
            ioProcID = nil
        }
        if aggregateID != kAudioObjectUnknown {
            AudioHardwareDestroyAggregateDevice(aggregateID)
            aggregateID = AudioObjectID(kAudioObjectUnknown)
        }
        if tapID != kAudioObjectUnknown {
            AudioHardwareDestroyProcessTap(tapID)
            tapID = AudioObjectID(kAudioObjectUnknown)
        }
    }

    /// Runs on the real-time I/O thread: no allocation, locks or Objective-C.
    /// The tap's streams follow any input streams of the clock device, so
    /// they are the last buffers: one interleaved buffer, or one per channel.
    private static func write(_ buffers: UnsafeMutableAudioBufferListPointer, to ring: OpaquePointer) {
        guard let last = buffers.last, let lastData = last.mData else { return }
        let samples = lastData.assumingMemoryBound(to: Float.self)
        let floatSize = UInt32(MemoryLayout<Float>.size)
        if last.mNumberChannels >= 2 {
            let frames = last.mDataByteSize / (floatSize * last.mNumberChannels)
            plug_ring_write(ring, samples, samples + 1, last.mNumberChannels, frames)
        } else if buffers.count >= 2, let leftData = buffers[buffers.count - 2].mData {
            let frames = last.mDataByteSize / floatSize
            plug_ring_write(ring, leftData.assumingMemoryBound(to: Float.self), samples, 1, frames)
        } else {
            plug_ring_write(ring, samples, samples, 1, last.mDataByteSize / floatSize)
        }
    }

    /// Plug's own Core Audio process object, excluded from the tap so Plug
    /// never captures (and feeds back) its own output.
    private static func ownProcessObject() throws -> AudioObjectID {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyTranslatePIDToProcessObject,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        var pid = getpid()
        var object = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        try check(AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address,
                                             UInt32(MemoryLayout<pid_t>.size), &pid, &size, &object),
                  "find Plug's own audio process")
        guard object != kAudioObjectUnknown else {
            throw CoreAudioError(action: "find Plug's own audio process to leave it out of the capture", status: noErr)
        }
        return object
    }
}
