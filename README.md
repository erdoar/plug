# Plug

A macOS audio host: capture application and system audio, route it through effects, and record or pass it on.

Status: early setup. Nothing builds yet.

See `CLAUDE.md` for the clean-room rules this project follows.

## Layout
- `Plug/PlugApp.swift`: app entry point.
- `Plug/HostModel.swift`: UI state (chain and engine).
- `Plug/Engine/`: `PluginChain` (pure model) and `AudioEngine` (AVAudioEngine skeleton, no routing or plugin loading yet).
- `Plug/UI/`: SwiftUI views.
- `Plug/Tests/`: unit tests for the pure chain model.

Not yet done: the Xcode project file, app/system audio capture, and AU plugin loading. These need a Mac to create and run.
