import PlugRingBuffer

/// Owns the ring buffer that carries captured audio from the capture I/O
/// thread to the engine's render thread. Whatever reads or writes the
/// pointer keeps a reference to this object, so the buffer outlives them.
final class CaptureRing: @unchecked Sendable {
    let pointer: OpaquePointer

    /// About a third of a second of headroom at 48 kHz; reads start once
    /// about 20 ms is buffered.
    init(capacityFrames: UInt32 = 16_384, prefillFrames: UInt32 = 1_024) {
        guard let pointer = plug_ring_create(capacityFrames, prefillFrames) else {
            fatalError("Couldn't allocate the capture ring buffer")
        }
        self.pointer = pointer
    }

    deinit {
        plug_ring_destroy(pointer)
    }
}
