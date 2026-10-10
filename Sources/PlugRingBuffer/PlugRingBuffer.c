#include "PlugRingBuffer.h"

#include <stdatomic.h>
#include <stdlib.h>
#include <string.h>

struct PlugRing {
    float *samples;                 /* interleaved stereo */
    uint32_t capacity;              /* frames, a power of two */
    uint32_t mask;
    uint32_t prefill;
    _Atomic uint64_t writeIndex;    /* total frames written */
    _Atomic uint64_t readIndex;     /* total frames read */
    int primed;                     /* reader only */
};

PlugRing *plug_ring_create(uint32_t capacityFrames, uint32_t prefillFrames) {
    uint32_t capacity = 1;
    while (capacity < capacityFrames && capacity < (1u << 30)) {
        capacity <<= 1;
    }
    PlugRing *ring = calloc(1, sizeof *ring);
    if (!ring) {
        return NULL;
    }
    ring->samples = calloc((size_t)capacity * 2, sizeof(float));
    if (!ring->samples) {
        free(ring);
        return NULL;
    }
    ring->capacity = capacity;
    ring->mask = capacity - 1;
    ring->prefill = prefillFrames <= capacity ? prefillFrames : capacity;
    atomic_init(&ring->writeIndex, 0);
    atomic_init(&ring->readIndex, 0);
    ring->primed = 0;
    return ring;
}

void plug_ring_destroy(PlugRing *ring) {
    if (ring) {
        free(ring->samples);
        free(ring);
    }
}

uint32_t plug_ring_write(PlugRing *ring, const float *left, const float *right,
                         uint32_t stride, uint32_t frames) {
    uint64_t write = atomic_load_explicit(&ring->writeIndex, memory_order_relaxed);
    uint64_t read = atomic_load_explicit(&ring->readIndex, memory_order_acquire);
    uint32_t space = ring->capacity - (uint32_t)(write - read);
    if (frames > space) {
        frames = space;
    }
    for (uint32_t i = 0; i < frames; i++) {
        size_t slot = (size_t)((write + i) & ring->mask) * 2;
        ring->samples[slot] = left[(size_t)i * stride];
        ring->samples[slot + 1] = right[(size_t)i * stride];
    }
    atomic_store_explicit(&ring->writeIndex, write + frames, memory_order_release);
    return frames;
}

uint32_t plug_ring_read(PlugRing *ring, float *left, float *right, uint32_t frames) {
    uint64_t read = atomic_load_explicit(&ring->readIndex, memory_order_relaxed);
    uint64_t write = atomic_load_explicit(&ring->writeIndex, memory_order_acquire);
    uint32_t available = (uint32_t)(write - read);
    uint32_t used = 0;
    if (!ring->primed && available >= ring->prefill) {
        ring->primed = 1;
    }
    if (ring->primed) {
        used = frames < available ? frames : available;
        for (uint32_t i = 0; i < used; i++) {
            size_t slot = (size_t)((read + i) & ring->mask) * 2;
            left[i] = ring->samples[slot];
            right[i] = ring->samples[slot + 1];
        }
        if (used < frames) {
            ring->primed = 0;  /* underrun: wait for the prefill again */
        }
        atomic_store_explicit(&ring->readIndex, read + used, memory_order_release);
    }
    for (uint32_t i = used; i < frames; i++) {
        left[i] = 0;
        right[i] = 0;
    }
    return used;
}

uint32_t plug_ring_available(PlugRing *ring) {
    uint64_t write = atomic_load_explicit(&ring->writeIndex, memory_order_acquire);
    uint64_t read = atomic_load_explicit(&ring->readIndex, memory_order_acquire);
    return (uint32_t)(write - read);
}
