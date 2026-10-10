import AVFoundation

/// A quiet sine wave, the engine's input until app and system audio capture
/// exist. Its state is only touched by the render thread after creation.
final class SineOscillator: @unchecked Sendable {
    private var phase = 0.0
    private let increment: Double
    private let amplitude: Float

    init(frequency: Double, amplitude: Float, sampleRate: Double) {
        self.increment = 2 * Double.pi * frequency / sampleRate
        self.amplitude = amplitude
    }

    /// The render block runs on the real-time audio thread: no allocation,
    /// locks or Objective-C messaging.
    func makeNode(format: AVAudioFormat) -> AVAudioSourceNode {
        AVAudioSourceNode(format: format) { [self] _, _, frameCount, bufferList in
            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            for frame in 0..<Int(frameCount) {
                let sample = Float(sin(phase)) * amplitude
                phase += increment
                if phase >= 2 * Double.pi { phase -= 2 * Double.pi }
                for buffer in buffers {
                    buffer.mData?.assumingMemoryBound(to: Float.self)[frame] = sample
                }
            }
            return noErr
        }
    }
}
