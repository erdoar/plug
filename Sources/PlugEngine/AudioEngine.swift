import AVFoundation

/// Owns the audio graph. Skeleton only: it starts and stops the default
/// engine and does not yet route app or system audio or load plugins.
public final class AudioEngine {
    private let engine = AVAudioEngine()
    public private(set) var isRunning = false

    public init() {}

    public func start() throws {
        guard !isRunning else { return }
        // Accessing the main mixer connects it to the output node, so the
        // graph has a path to the output device before it starts.
        _ = engine.mainMixerNode
        engine.prepare()
        try engine.start()
        isRunning = true
    }

    public func stop() {
        guard isRunning else { return }
        engine.stop()
        isRunning = false
    }
}
