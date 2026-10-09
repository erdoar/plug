# Plug: working notes for Claude

A macOS audio host, built as a clean-room re-implementation of the features of a commercial audio-routing app (Audio Hijack-style: capture app and system audio, route it through effects, record or pass it on).

## Clean-room rules
- Build from Apple's public APIs and documentation only: CoreAudio, AVFoundation, Audio Unit / AUv3, Audio Taps (`AudioHardwareCreateProcessTap`), and documented driver interfaces.
- Never copy code, decompiled output, strings, resource files, or internal data formats from any third-party app into this repo. Behaviour may be observed and described in our own words.
- Reverse-engineering notes from analysis tools live in `docs/research/`. They describe observed behaviour only, never code, and never feed directly into the implementation.
- Do not ship any third-party binary, icon, or asset.

## Layout
- `Plug/`: the app (SwiftUI front end, audio engine in Swift/C).
- `docs/research/`: observed behaviour notes (no code).
- `docs/`: design notes.

## Working rules
- Keep the audio engine independent of the UI so it can be tested without a window.
- Real-time audio thread: no allocation, locks, or Objective-C messaging inside the render callback.
- Say what was tested and on what hardware. Do not claim a feature works on macOS without running it there.
