import PlugRingBuffer
import XCTest

final class RingBufferTests: XCTestCase {
    private var ring: OpaquePointer!

    override func tearDown() {
        plug_ring_destroy(ring)
        ring = nil
    }

    private func read(_ frames: Int) -> (used: UInt32, left: [Float], right: [Float]) {
        var left = [Float](repeating: -1, count: frames)
        var right = [Float](repeating: -1, count: frames)
        let used = plug_ring_read(ring, &left, &right, UInt32(frames))
        return (used, left, right)
    }

    func testSilentUntilPrefillThenSamplesInOrder() {
        ring = plug_ring_create(8, 4)
        XCTAssertEqual(plug_ring_write(ring, [1, 2, 3], [10, 20, 30], 1, 3), 3)
        let early = read(2)
        XCTAssertEqual(early.used, 0)
        XCTAssertEqual(early.left, [0, 0])

        plug_ring_write(ring, [4], [40], 1, 1)
        let primed = read(2)
        XCTAssertEqual(primed.used, 2)
        XCTAssertEqual(primed.left, [1, 2])
        XCTAssertEqual(primed.right, [10, 20])
        XCTAssertEqual(plug_ring_available(ring), 2)
    }

    func testInterleavedInput() {
        ring = plug_ring_create(8, 1)
        let interleaved: [Float] = [1, 10, 2, 20, 3, 30]
        interleaved.withUnsafeBufferPointer { samples in
            XCTAssertEqual(plug_ring_write(ring, samples.baseAddress, samples.baseAddress! + 1, 2, 3), 3)
        }
        let out = read(3)
        XCTAssertEqual(out.left, [1, 2, 3])
        XCTAssertEqual(out.right, [10, 20, 30])
    }

    func testMonoInputGoesToBothChannels() {
        ring = plug_ring_create(8, 1)
        let mono: [Float] = [5, 6]
        mono.withUnsafeBufferPointer { samples in
            plug_ring_write(ring, samples.baseAddress, samples.baseAddress, 1, 2)
        }
        let out = read(2)
        XCTAssertEqual(out.left, [5, 6])
        XCTAssertEqual(out.right, [5, 6])
    }

    func testCapacityRoundsUpAndOverflowIsDropped() {
        ring = plug_ring_create(3, 1)  // rounds up to 4
        XCTAssertEqual(plug_ring_write(ring, [1, 2, 3, 4, 5, 6], [1, 2, 3, 4, 5, 6], 1, 6), 4)
        XCTAssertEqual(read(4).left, [1, 2, 3, 4])
    }

    func testUnderrunFillsSilenceAndWaitsForPrefillAgain() {
        ring = plug_ring_create(8, 2)
        plug_ring_write(ring, [1, 2], [1, 2], 1, 2)
        let short = read(3)
        XCTAssertEqual(short.used, 2)
        XCTAssertEqual(short.left, [1, 2, 0])

        plug_ring_write(ring, [3], [3], 1, 1)
        XCTAssertEqual(read(1).used, 0, "one frame is below the prefill of two")
        plug_ring_write(ring, [4], [4], 1, 1)
        XCTAssertEqual(read(2).left, [3, 4])
    }

    func testWrapsAroundTheEnd() {
        ring = plug_ring_create(4, 1)
        for start in stride(from: Float(0), to: 20, by: 3) {
            let chunk: [Float] = [start, start + 1, start + 2]
            XCTAssertEqual(plug_ring_write(ring, chunk, chunk, 1, 3), 3)
            XCTAssertEqual(read(3).left, chunk)
        }
    }

    /// One writer thread and one reader thread, as in real use: every value
    /// written comes out once, in order, with only silence in between.
    func testConcurrentWriterAndReaderKeepOrder() {
        ring = plug_ring_create(256, 16)
        let total = 200_000
        let ring = self.ring!
        let writer = Thread {
            var next: Float = 1
            var chunk = [Float](repeating: 0, count: 64)
            while next <= Float(total) {
                let count = min(chunk.count, total - Int(next) + 1)
                for i in 0..<count { chunk[i] = next + Float(i) }
                let written = chunk.withUnsafeBufferPointer { samples in
                    plug_ring_write(ring, samples.baseAddress, samples.baseAddress, 1, UInt32(count))
                }
                next += Float(written)
            }
        }
        writer.start()

        var expected: Float = 1
        var left = [Float](repeating: 0, count: 48)
        var right = [Float](repeating: 0, count: 48)
        let deadline = Date().addingTimeInterval(20)
        while expected <= Float(total), Date() < deadline {
            let used = Int(plug_ring_read(ring, &left, &right, 48))
            for i in 0..<used {
                XCTAssertEqual(left[i], expected)
                XCTAssertEqual(right[i], expected)
                expected += 1
            }
            for i in used..<48 { XCTAssertEqual(left[i], 0) }
        }
        XCTAssertEqual(expected, Float(total) + 1, "reader received every frame")
    }
}
