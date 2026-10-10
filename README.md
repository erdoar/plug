# Plug

An Audio Unit plugin host for macOS. Plug sits between apps or system audio and your playback devices, loads AU effect plugins into that path, and sends the processed audio to the output device.

Status: early. Captures everything the Mac plays, or just the apps you pick (or a test tone), runs it through Audio Unit effects you pick from the ones installed on your Mac, and plays it to the output device you choose. While capturing, other apps are heard only through Plug.

See `CLAUDE.md` for the clean-room rules this project follows.

How to use Plug: see the [user manual](MANUAL.md). Website graphics and the manual as a web page are in [`Web/`](Web/).

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
- `Bundle/AppIcon.iconset/`: the app icon at every macOS size. Sources and web graphics are in `Branding/`.
- `scripts/bundle.sh`: builds `build/Plug.app` and signs it ad hoc.
- `Sources/PlugCore/`: plain-Swift models (`PluginChain`, `EffectID`). Builds on any platform.
- `Sources/PlugRingBuffer/`: a lock-free C ring buffer that carries captured audio to the render thread. Builds on any platform.
- `Sources/PlugEngine/`: the audio engine. `AudioEngine` wires input (test tone or system audio) -> effects -> output; `SystemAudioTap` captures system audio through a Core Audio process tap; `EffectCatalog` lists installed AU effects. macOS only, no UI.
- `Sources/Plug/`: the SwiftUI app (`PlugApp`, `HostModel`, `PluginWindows` for effect controls, `UI/`). macOS only.
- `Tests/PlugCoreTests/`, `Tests/PlugRingBufferTests/`: unit tests that also run on Linux.
- `Tests/PlugEngineTests/`: engine tests using Apple's built-in AUDelay. macOS only; they wire the graph but play no sound.

## Quick volume
Right-click Plug's Dock icon for Start/Stop and the master level in steps (+10 dB to mute). The VU meter icon in the menu bar opens a master volume slider with Start/Stop. Both move the same master as the knob and MIDI. Closing the window leaves Plug running; click the Dock icon or "Open Plug" in the menu bar to bring it back.

## Releasing
"Check for Updates" compares the app's version with the newest GitHub release. To publish one:
1. Raise `CFBundleShortVersionString` in `Bundle/Info.plist` (e.g. `0.2.0`) and merge.
2. Run `scripts/bundle.sh`, then `ditto -c -k --keepParent build/Plug.app Plug-0.2.0.zip`.
3. On GitHub, create a release tagged `v0.2.0` and attach the zip.

## Presets
The strip at the bottom saves the whole setup (input, apps, output, effects with their settings, and the master level) as a named preset, and recalls it from the preset knob. Presets are JSON files in `~/Library/Application Support/Plug/Presets/`. The MIDI assignment isn't part of a preset; it stays with your controller.

## Known limits
- The master knob sits after the effect chain and goes from silence to +10 dB; 0 dB is at 80% of the turn, marked by the bent tack (click the tack to return there). Boosted audio that goes over full scale clips at the output. MIDI Learn binds it to one control change (channel and controller) from any MIDI source; MIDI is receive-only, so motorised faders aren't moved to match.
- `swift run` starts the app without an `.app` bundle or `Info.plist`, so anything that needs permission must be run from `scripts/bundle.sh` instead.
- The bundle is signed ad hoc, so macOS may ask for permission again after each rebuild.
- System audio capture needs the bundled app and macOS's System Audio Recording permission (System Settings > Privacy & Security > Screen & System Audio Recording).
- With the Apps input, apps are matched by bundle ID with their helper processes; an app opened while Plug runs joins at the next Start. Safari and other WebKit apps share one audio process, so they are captured together. Input, output and the effect chain (with each effect's settings) are saved to `~/Library/Application Support/Plug/settings.json` and restored on launch; Plug never starts playing by itself.
