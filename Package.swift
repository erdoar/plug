// swift-tools-version:5.9
import PackageDescription

// PlugCore is plain Swift and builds anywhere, so its tests also run on Linux.
// The engine and the app use Apple frameworks (AVFoundation, SwiftUI) and are
// only added when building on macOS.
var targets: [Target] = [
    .target(name: "PlugCore"),
    .testTarget(name: "PlugCoreTests", dependencies: ["PlugCore"]),
]

#if os(macOS)
targets += [
    .target(name: "PlugEngine"),
    .executableTarget(name: "Plug", dependencies: ["PlugCore", "PlugEngine"]),
]
#endif

let package = Package(
    name: "Plug",
    platforms: [.macOS(.v14)],
    targets: targets
)
