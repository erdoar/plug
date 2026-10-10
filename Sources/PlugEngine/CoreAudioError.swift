import CoreAudio
import Foundation

/// A failed Core Audio call, with what Plug was trying to do.
struct CoreAudioError: LocalizedError {
    let action: String
    let status: OSStatus

    var errorDescription: String? {
        status == noErr
            ? "Couldn't \(action)."
            : "Couldn't \(action) (Core Audio error \(status))."
    }
}

func check(_ status: OSStatus, _ action: String) throws {
    guard status == noErr else { throw CoreAudioError(action: action, status: status) }
}
