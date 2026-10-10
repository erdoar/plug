// swift-tools-version:5.9
import PackageDescription

// PlugCore (plain Swift) and PlugRingBuffer (plain C) build anywhere, so their
// tests also run on Linux. The engine and the app use Apple frameworks
// (Core Audio, AVFoundation, SwiftUI) and are only added on macOS.
var targets: [Target] = [
    .target(name: "PlugCore"),
    .target(name: "PlugRingBuffer"),
    .testTarget(name: "PlugCoreTests", dependencies: ["PlugCore"]),
    .testTarget(name: "PlugRingBufferTests", dependencies: ["PlugRingBuffer"]),
]

#if os(macOS)
targets += [
    .target(name: "PlugEngine", dependencies: ["PlugCore", "PlugRingBuffer"]),
    .executableTarget(name: "Plug", dependencies: ["PlugCore", "PlugEngine"]),
    .testTarget(name: "PlugEngineTests", dependencies: ["PlugCore", "PlugEngine"]),
]
#endif

let package = Package(
    name: "Plug",
    // Core Audio process taps need macOS 14.2.
    platforms: [.macOS("14.2")],
    targets: targets
)
