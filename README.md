# Plug

An Audio Unit plugin host for macOS. Plug sits between apps or system audio and your playback devices, loads AU effect plugins into that path, and sends the processed audio to the output device.

Status: early. Captures everything the Mac plays, or just the apps you pick (or a test tone), runs it through Audio Unit effects you pick from the ones installed on your Mac, and plays it to the output device you choose. While capturing, other apps are heard only through Plug.

See `CLAUDE.md` for the clean-room rules this project follows.

How to use Plug: see the [user guide](MANUAL.md) (written for people who install from the DMG). Website graphics and the manual as a web page are in [`Web/`](Web/).

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

## Buttons
People add their own buttons to the menu bar panel in Plug > Settings… (or "Edit Buttons…" in the panel). A button can control Plug (Start/Stop, recall a preset, set the master level, bypass an effect), send a MIDI control change, note or program change to any MIDI output, run a zsh command, run a Shortcut, open a link, file or app, or ask Claude through Claude Code (`claude -p`, with the person's own sign-in; Plug stores no key). A Claude button can start in a chosen folder, so a prompt like `/run` runs that project's slash command or skill. It runs with `--permission-mode dontAsk` (read and answer) or `acceptEdits`, plus any `--allowedTools` the person names. Nothing else is allowed, since nobody is there to approve it. The repo has one such command, `/plug-build [branch]` (`.claude/skills/plug-build/`): it pulls, runs `swift test` and `scripts/bundle.sh`, and reports in a few lines. A button for it uses this folder, "Read and answer only", and Also allow `Bash(git status *),Bash(git fetch *),Bash(git checkout *),Bash(git pull *),Bash(git log *),Bash(swift test),Bash(scripts/bundle.sh)`. Commands run from the home folder; their output, or Claude's reply, can open in a window. Clicking a running button stops it. Buttons are saved in `~/Library/Application Support/Plug/buttons.json`, apart from presets. The format and the MIDI words are in `PlugCore/QuickButtons.swift`; `PlugEngine/MIDIOutput.swift` sends MIDI.

## Releasing
"Check for Updates" compares the app's version with the newest GitHub release. To publish one:
1. Raise `CFBundleShortVersionString` in `Bundle/Info.plist` (e.g. `0.2.0`) and merge.
2. Run `scripts/make-dmg.sh`. It builds Plug and writes `build/Plug-0.2.0.dmg`: the app and an Applications shortcut to drag it onto.
3. On GitHub, create a release tagged `v0.2.0` and attach the DMG. "Check for Updates" sends people to the releases page.

The app is signed ad hoc, not notarized, so the first time people open it they right-click it and choose Open (the manual says so). Notarizing needs an Apple Developer account.

## Presets
The strip at the bottom saves the whole setup (input, apps, output, effects with their settings, and the master level) as a named preset, and recalls it from the preset knob. Presets are JSON files in `~/Library/Application Support/Plug/Presets/`. The MIDI assignment isn't part of a preset; it stays with your controller.

## Known limits
- The master knob sits after the effect chain and goes from silence to +10 dB; 0 dB is at 80% of the turn, marked by the bent tack (click the tack to return there). Boosted audio that goes over full scale clips at the output. MIDI Learn binds it to one control change (channel and controller) from any MIDI source; MIDI in is only for the master knob, and motorised faders aren't moved to match; MIDI out is only for buttons.
- `swift run` starts the app without an `.app` bundle or `Info.plist`, so anything that needs permission must be run from `scripts/bundle.sh` instead.
- The bundle is signed ad hoc, so macOS may ask for permission again after each rebuild.
- System audio capture needs the bundled app and macOS's System Audio Recording permission (System Settings > Privacy & Security > Screen & System Audio Recording).
- With the Apps input, apps are matched by bundle ID with their helper processes; an app opened while Plug runs joins at the next Start. Safari and other WebKit apps share one audio process, so they are captured together. Input, output and the effect chain (with each effect's settings) are saved to `~/Library/Application Support/Plug/settings.json` and restored on launch; Plug never starts playing by itself.
