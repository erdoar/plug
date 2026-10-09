import AVFoundation

/// Owns the audio graph. Skeleton only: it starts and stops the default
/// engine and does not yet route app or system audio or load plugins.
final class AudioEngine {
    private let engine = AVAudioEngine()
    private(set) var isRunning = false

    func start() throws {
        guard !isRunning else { return }
        engine.prepare()
        try engine.start()
        isRunning = true
    }

    func stop() {
        guard isRunning else { return }
        engine.stop()
        isRunning = false
    }
}
