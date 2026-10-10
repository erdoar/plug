# Plug

An Audio Unit plugin host for macOS. Plug sits between apps or system audio and your playback devices, loads AU effect plugins into that path, and sends the processed audio to the output device.

Status: early skeleton. A window with a placeholder effect chain; no audio routing or plugin loading yet.

See `CLAUDE.md` for the clean-room rules this project follows.

## Build and run (macOS 14 or newer)
Plug is a Swift package. There is no Xcode project file.

```
swift build          # build everything
swift test           # run the unit tests
swift run Plug       # launch the app
```

To work in Xcode instead, open the folder that contains `Package.swift` (File > Open, or `open Package.swift`). Xcode shows a `Plug` scheme: Cmd+R runs the app, Cmd+U runs the tests.

## Layout
- `Package.swift`: the package manifest.
- `Sources/PlugCore/`: plain-Swift models (`PluginChain`). Builds on any platform.
- `Sources/PlugEngine/`: the audio engine (`AudioEngine`, an AVAudioEngine skeleton). macOS only, no UI.
- `Sources/Plug/`: the SwiftUI app (`PlugApp`, `HostModel`, `UI/`). macOS only.
- `Tests/PlugCoreTests/`: unit tests for `PlugCore`.

## Known limits
- `swift run` starts the app without an `.app` bundle, so it has no `Info.plist`. macOS needs one to ask for microphone or audio-capture permission. Before audio capture is added, the build needs a step that wraps the app in a bundle.
- Not yet done: app and system audio capture, AU plugin loading.
