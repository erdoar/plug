#ifndef PLUG_RING_BUFFER_H
#define PLUG_RING_BUFFER_H

#include <stdint.h>

/// A single-producer, single-consumer ring buffer of stereo float frames.
/// One thread writes (the capture I/O thread), one thread reads (the render
/// thread). Reads and writes never allocate, lock or block, so both are safe
/// on real-time audio threads. Create and destroy it off those threads.
typedef struct PlugRing PlugRing;

/// `capacityFrames` is rounded up to a power of two. After starting, and
/// after any underrun, reads return silence until `prefillFrames` frames are
/// buffered, which absorbs timing jitter between the two threads.
PlugRing *plug_ring_create(uint32_t capacityFrames, uint32_t prefillFrames);
void plug_ring_destroy(PlugRing *ring);

/// Writer side. Copies up to `frames` frames; frame i is read from
/// left[i * stride] and right[i * stride]. For interleaved stereo pass
/// (data, data + 1, 2); for separate channels pass (left, right, 1); for mono
/// pass the same pointer twice. Frames that don't fit are dropped. Returns the
/// number of frames written.
uint32_t plug_ring_write(PlugRing *ring, const float *left, const float *right,
                         uint32_t stride, uint32_t frames);

/// Reader side. Fills `frames` frames of `left` and `right`, using silence for
/// anything not available. Returns the number of buffered frames used.
uint32_t plug_ring_read(PlugRing *ring, float *left, float *right, uint32_t frames);

/// Frames currently buffered. A snapshot; for tests and diagnostics.
uint32_t plug_ring_available(PlugRing *ring);

#endif
