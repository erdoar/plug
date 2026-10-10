# Plug: working notes for Claude

A macOS audio host, built as a clean-room re-implementation of the features of a commercial audio-routing app (Audio Hijack-style: capture app and system audio, route it through effects, record or pass it on).

## Clean-room rules
- Build from Apple's public APIs and documentation only: CoreAudio, AVFoundation, Audio Unit / AUv3, Audio Taps (`AudioHardwareCreateProcessTap`), and documented driver interfaces.
- Never copy code, decompiled output, strings, resource files, or internal data formats from any third-party app into this repo. Behaviour may be observed and described in our own words.
- Reverse-engineering notes from analysis tools live in `docs/research/`. They describe observed behaviour only, never code, and never feed directly into the implementation.
- Do not ship any third-party binary, icon, or asset.

## Layout
- `Package.swift`: a Swift package; there is no Xcode project file.
- `Sources/PlugCore/`: plain-Swift models. Builds on any platform, Linux included.
- `Sources/PlugEngine/`: the audio engine (AVFoundation, CoreAudio). macOS only, no UI.
- `Sources/Plug/`: the SwiftUI app. macOS only.
- `Tests/PlugCoreTests/`: unit tests for PlugCore.
- `docs/research/`: observed behaviour notes (no code).
- `docs/`: design notes.

## Build and test
- `swift build`, `swift test`, `swift run Plug` from the repo root. On Linux only PlugCore and its tests build; the engine and app targets are added only on macOS (see `Package.swift`).
- `swift run` launches the app without an `.app` bundle or `Info.plist`, so it cannot ask for microphone or audio-capture permission. Add a bundling step before any feature that needs one.

## Working rules
- Keep the audio engine independent of the UI so it can be tested without a window.
- Real-time audio thread: no allocation, locks, or Objective-C messaging inside the render callback.
- Say what was tested and on what hardware. Do not claim a feature works on macOS without running it there.
