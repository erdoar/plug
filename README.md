# Plug

An Audio Unit plugin host for macOS. Plug sits between apps or system audio and your playback devices, loads AU effect plugins into that path, and sends the processed audio to the output device.

Status: early. Captures everything the Mac plays (or a test tone), runs it through Audio Unit effects you pick from the ones installed on your Mac, and plays it to the output device you choose. While capturing, other apps are heard only through Plug.

See `CLAUDE.md` for the clean-room rules this project follows.

## Build and run (macOS 14.2 or newer)
Plug is a Swift package. There is no Xcode project file.

```
swift build          # build everything
swift test           # run the unit tests
swift run Plug       # launch the app
```

To build a proper app bundle, which macOS needs before it will grant audio-capture or microphone permission:

```
scripts/bundle.sh --open   # builds build/Plug.app and launches it
```

To work in Xcode instead, open the folder that contains `Package.swift` (File > Open, or `open Package.swift`). Xcode shows a `Plug` scheme: Cmd+R runs the app, Cmd+U runs the tests.

## Layout
- `Package.swift`: the package manifest.
- `Bundle/Info.plist`: the app bundle's Info.plist template, including the permission prompts' wording.
- `scripts/bundle.sh`: builds `build/Plug.app` and signs it ad hoc.
- `Sources/PlugCore/`: plain-Swift models (`PluginChain`, `EffectID`). Builds on any platform.
- `Sources/PlugRingBuffer/`: a lock-free C ring buffer that carries captured audio to the render thread. Builds on any platform.
- `Sources/PlugEngine/`: the audio engine. `AudioEngine` wires input (test tone or system audio) -> effects -> output; `SystemAudioTap` captures system audio through a Core Audio process tap; `EffectCatalog` lists installed AU effects. macOS only, no UI.
- `Sources/Plug/`: the SwiftUI app (`PlugApp`, `HostModel`, `PluginWindows` for effect controls, `UI/`). macOS only.
- `Tests/PlugCoreTests/`, `Tests/PlugRingBufferTests/`: unit tests that also run on Linux.
- `Tests/PlugEngineTests/`: engine tests using Apple's built-in AUDelay. macOS only; they wire the graph but play no sound.

## Known limits
- `swift run` starts the app without an `.app` bundle or `Info.plist`, so anything that needs permission must be run from `scripts/bundle.sh` instead.
- The bundle is signed ad hoc, so macOS may ask for permission again after each rebuild.
- System audio capture needs the bundled app and macOS's System Audio Recording permission (System Settings > Privacy & Security > Screen & System Audio Recording).
- Not yet done: capturing single apps. Choices are not remembered between launches.
