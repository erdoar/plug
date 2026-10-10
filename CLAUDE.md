# Plug: working notes for Claude

An Audio Unit (AU) plugin host for macOS. It sits between apps or system audio and the physical or external playback devices, loads AU effect plugins into that path, and passes the processed audio on to the output device.

## Clean-room rules
- Build from Apple's public APIs and documentation only: CoreAudio, AVFoundation, Audio Unit / AUv3, Audio Taps (`AudioHardwareCreateProcessTap`), and documented driver interfaces.
- Never copy code, decompiled output, strings, resource files, or internal data formats from any third-party app into this repo. Behaviour may be observed and described in our own words.
- Reverse-engineering notes from analysis tools live in `docs/research/`. They describe observed behaviour only, never code, and never feed directly into the implementation.
- Do not ship any third-party binary, icon, or asset.

## Layout
- `Package.swift`: a Swift package; there is no Xcode project file.
- `Sources/PlugCore/`: plain-Swift models. Builds on any platform, Linux included.
- `Sources/PlugRingBuffer/`: plain-C lock-free ring buffer between the capture I/O thread and the render thread. Builds on any platform; its tests include a two-thread stress test (run it under `--sanitize=thread` after changes).
- `Sources/PlugEngine/`: the audio engine (AVFoundation, CoreAudio). macOS only, no UI.
- `Sources/Plug/`: the SwiftUI app. macOS only.
- `Tests/PlugCoreTests/`, `Tests/PlugRingBufferTests/`: unit tests that also run on Linux.
- `Tests/PlugEngineTests/`: engine tests (macOS only). They use Apple's built-in AUs and never start the engine, so they make no sound and never capture.
- Audio path: app or system audio -> Plug's capture stage -> AU effect chain -> chosen output device. Plugin loading uses AUv3 and AudioUnit APIs only.
- `docs/research/`: observed behaviour notes (no code).
- `docs/`: design notes.

## Build and test
- `swift build`, `swift test`, `swift run Plug` from the repo root. On Linux only PlugCore and its tests build; the engine and app targets are added only on macOS (see `Package.swift`).
- `swift run` launches the app without an `.app` bundle or `Info.plist`, so it cannot ask for microphone or audio-capture permission. `scripts/bundle.sh` builds `build/Plug.app` from `Bundle/Info.plist` and signs it ad hoc; use it for anything that needs permission. New usage-description keys go in `Bundle/Info.plist`.

## Working rules
- Keep the audio engine independent of the UI so it can be tested without a window.
- Real-time audio threads (the render callbacks and the capture I/O block): no allocation, locks, or Objective-C messaging.
- Capture (system audio or chosen apps) mutes the captured apps at the speakers while it runs (the tap's mute behaviour), so it must only run while the engine plays, and must always exclude Plug's own process.
- Say what was tested and on what hardware. Do not claim a feature works on macOS without running it there.
