import CoreAudio
import Foundation
import PlugCore

/// A process that has opened Core Audio, as the system lists it.
public struct AudioProcess: Hashable {
    public let objectID: AudioObjectID
    public let pid: pid_t
    public let bundleID: String
    /// Whether it is sending audio to an output right now.
    public let isPlaying: Bool

    /// The app this process belongs to (helpers group with their app).
    public var appKey: String { AppKey.forBundleID(bundleID) }
}

/// Reads Core Audio's process list. Plug itself is never included.
public enum AudioProcesses {
    public static func all() -> [AudioProcess] {
        let system = AudioObjectID(kAudioObjectSystemObject)
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyProcessObjectList,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr else { return [] }
        var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(system, &address, 0, nil, &size, &ids) == noErr else { return [] }
        let ownPID = getpid()
        return ids.compactMap { id in
            guard let pid = value(id, kAudioProcessPropertyPID, as: pid_t(0)), pid != ownPID,
                  let bundleID = string(id, kAudioProcessPropertyBundleID), !bundleID.isEmpty else { return nil }
            let playing = value(id, kAudioProcessPropertyIsRunningOutput, as: UInt32(0)) ?? 0
            return AudioProcess(objectID: id, pid: pid, bundleID: bundleID, isPlaying: playing != 0)
        }
    }

    private static func value<T>(_ id: AudioObjectID, _ selector: AudioObjectPropertySelector, as initial: T) -> T? {
        var address = AudioObjectPropertyAddress(mSelector: selector,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        var result = initial
        var size = UInt32(MemoryLayout<T>.size)
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &result) == noErr else { return nil }
        return result
    }

    private static func string(_ id: AudioObjectID, _ selector: AudioObjectPropertySelector) -> String? {
        var address = AudioObjectPropertyAddress(mSelector: selector,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        var result: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &result) == noErr,
              let result else { return nil }
        return result.takeRetainedValue() as String
    }
}
