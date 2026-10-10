# Plug: user manual

Plug is an Audio Unit host for your Mac. It takes the sound your Mac plays (everything, or only the apps you choose), runs it through Audio Unit effects, and plays the result to the output you pick. While Plug is playing, the audio it captures is heard only through Plug, so you hear the effected version and not the original as well.

## Contents

1. [What you need](#what-you-need)
2. [Install](#install)
3. [The first run](#the-first-run)
4. [A tour of the window](#a-tour-of-the-window)
5. [Inputs](#inputs)
6. [Output](#output)
7. [Effects](#effects)
8. [The master knob](#the-master-knob)
9. [MIDI control](#midi-control)
10. [Presets](#presets)
11. [Dock menu and menu bar](#dock-menu-and-menu-bar)
12. [Help, About and updates](#help-about-and-updates)
13. [Where Plug keeps things](#where-plug-keeps-things)
14. [Troubleshooting](#troubleshooting)

## What you need

- A Mac running **macOS 14.2 (Sonoma) or later**. Plug captures audio with Core Audio process taps, which arrived in 14.2.
- To build Plug from source: **Xcode** (from the App Store), with Xcode selected for command-line builds:

  ```
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  ```

- Any Audio Unit effects you want to use. macOS includes Apple's own (AUDelay, AUReverb, AUGraphicEQ and more); third-party Audio Unit plugins appear too.
- Optional: a MIDI controller, to turn the master volume from hardware.

## Install

In Terminal, from the folder containing Plug's source:

```
scripts/bundle.sh --open
```

This builds Plug and wraps it in `build/Plug.app`, then opens it. To keep it handy, drag `build/Plug.app` to the Dock or to Applications.

Plug is signed for your Mac only (an "ad hoc" signature). This means:

- macOS may ask for permission again after you rebuild.
- After a rebuild the Dock can keep showing an old icon. If so, remove Plug from the Dock and drag `build/Plug.app` back in.

Quit Plug before rebuilding or running `swift test`. While Plug runs from `swift run`, the build folder is locked.

## The first run

Plug opens stopped, playing nothing. Nothing is captured or muted until you press **START**.

The first time you start Plug with **System audio** or **Apps** as the input, macOS asks to allow **System Audio Recording**. Allow it. If you said no, or you hear nothing, turn Plug on in **System Settings > Privacy & Security > Screen & System Audio Recording**, then press **STOP** and **START** again.

**Keep your volume low the first time.** The master knob can boost by up to 10 dB.

## A tour of the window

The window has three parts: the **top board**, the **drawer** in the middle, and the **preset strip** at the bottom.

### The top board

From left to right:

| Control | What it does |
|---|---|
| **START** (green lamp) | Starts Plug. The green lamp glows while Plug plays. |
| **STOP** (red lamp) | Stops Plug. The red lamp glows while Plug is stopped. Stopping ends any capture, so other apps play normally again. |
| **MASTER** knob | The level after all the effects. Drag up or down to turn it. The scale above shows the level in dB. See [The master knob](#the-master-knob). |
| Bent tack | Marks 0 dB beside the master knob. Click it to return the knob to 0 dB. |
| **MIDI LEARN** plate | Links the master knob to a knob or fader on a MIDI controller. See [MIDI control](#midi-control). |
| **INPUT** dial | What goes into the effects: test tone, system audio, or chosen apps. |
| **OUTPUT** dial | Where Plug plays: speakers, headphones, an interface. |
| **ADD** dial | Adds an Audio Unit effect to the end of the chain. |

The three dials work like an old radio's band selector. Click the knob to open its choices, and pick one. The pointer and the needle on the scale move to your choice, and the scale shows its name.

### The drawer

Click the worn iron **handle** in the middle of the preset strip to open or close the drawer. The window grows and shrinks with it, and Plug remembers whether you left it open.

The drawer holds:

- A note about the current input.
- With the **Apps** input, the list of apps to tick.
- The **effect chain**, top to bottom in the order audio passes through.

### The preset strip

From left to right: the **PRESETS** label, a scale showing the current preset's name, the drawer handle in the centre, the **preset knob** (click to open the preset list), and the **SAVE** plate. See [Presets](#presets).

## Inputs

Choose the input on the **INPUT** dial.

**Test tone.** A quiet 440 Hz tone, for trying effects without playing anything. Nothing is captured.

**System audio.** Everything your Mac plays, except Plug itself. While Plug plays, all other apps are heard only through Plug.

**Apps.** Only the apps you tick. Ticked apps are heard only through Plug; every other app plays normally. With **Apps** selected, the drawer lists:

- apps that are playing sound now, marked *playing*;
- other open apps that have used audio;
- any app you've ticked before, even if it's closed.

Click the refresh arrow to update the list.

Things to know about **Apps**:

- An app's helper processes count as part of the app. Chrome, Spotify, Slack and similar apps play sound from helpers, and ticking the app captures them all.
- Safari and other apps built on Apple's web engine play web audio from one shared process. It appears as a single entry, **Safari and web views**, so they're captured together.
- Plug finds the ticked apps when it starts. An app opened while Plug is running joins at the next **STOP** and **START**.
- If none of the ticked apps is open, Plug says so and captures nothing.

## Output

Choose where Plug plays on the **OUTPUT** dial. It lists every output on your Mac. If you plug something in while Plug is open, open the dial and click **Refresh devices**.

You can switch output while Plug plays. While capturing, Plug keeps time with the output it started on. If you hear occasional clicks after switching, press **STOP** and **START** to resync.

## Effects

**Add an effect.** Click the **ADD** dial and pick one. Effects are grouped by maker. Each new effect goes on the end of the chain.

In the drawer, each effect has:

| Control | What it does |
|---|---|
| **Bypass** | Passes audio through the effect untouched. Its settings are kept. |
| Sliders icon | Opens the effect's controls in a window: the plugin's own interface, or Apple's generic sliders for effects without one. |
| Bin | Removes the effect and closes its window. |

**Reorder** by dragging an effect up or down. The sound follows the new order straight away.

Plug remembers the chain and every effect's settings when you quit. That includes changes made in the effects' own windows.

## The master knob

The master knob sets the level after the whole effect chain.

- **0 dB** sits at 80% of the knob's turn, marked by the **bent tack**. At 0 dB, Plug neither raises nor lowers the level.
- Below the tack, the level falls smoothly to silence. Halfway to the tack is about −18 dB.
- Above the tack, the level rises evenly to **+10 dB** at the top. Boosted audio that goes past full scale will distort, so use the boost with care.
- **Drag up or down** on the knob to turn it.
- **Click the tack** to snap back to 0 dB.
- With VoiceOver, use the adjust gestures.

## MIDI control

Plug listens to every MIDI source on your Mac: USB and Bluetooth controllers, and other apps through the IAC Driver. Devices plugged in while Plug runs are picked up too.

**To link a hardware knob or fader to the master:**

1. Click the **MIDI LEARN** plate. It reads **MOVE A CONTROL** and pulses.
2. Move the knob or fader on your controller.
3. The plate now shows the control, e.g. **CC 7 · CH 1**. Turning it turns the master.

The control's full travel covers silence to +10 dB, with 0 dB at about value 102.

- **To change it:** click the plate again and move another control.
- **To cancel learning:** click the plate again before moving anything.
- **To remove the link:** right-click the plate and choose **Forget MIDI control**.

MIDI only comes in. Plug can't move a motorised fader to match the on-screen knob.

## Presets

A preset stores the whole setup:

- the input, and the ticked apps;
- the output device;
- every effect, in order, with all its settings and bypass state;
- the master level.

The MIDI link isn't part of presets. It stays with your controller.

**Save a preset.** Click **SAVE**, type a name and press **Save**. Saving with an existing name replaces that preset.

**Recall a preset.** Click the **preset knob** and click a name. Plug loads it straight away. Recalling never starts or stops playback by itself.

**Delete a preset.** Click the bin beside its name in the list.

## Dock menu and menu bar

**Dock menu.** Right-click Plug's Dock icon for:

- **Start** or **Stop**;
- the master level in steps (+10, +6, +3, 0, −3, −6, −12, −24 dB, and Mute), with the nearest one ticked.

**Menu bar.** Click the VU meter icon at the top of the screen for:

- a master volume slider, and the level in dB;
- **0 dB**, to return to unity;
- **Start** or **Stop**;
- **Open Plug**, to bring back the window;
- **Quit**.

The Dock menu, the menu bar, the on-screen knob and your MIDI control all move the same master, so they always agree.

Closing the window doesn't stop Plug, which keeps playing. Click the Dock icon or choose **Open Plug** to bring the window back. Quit Plug to stop completely.

## Help, About and updates

- **Help > Plug Help** (Cmd+?) opens this manual in your browser. It's built into Plug.app, so it works offline.
- **Plug > About Plug** shows Plug's version.
- **Plug > Check for Updates…** asks Plug's GitHub page for the latest release. If a newer one exists, Plug offers to open its download page. If you build Plug yourself, update by running `git pull`, then `scripts/bundle.sh`.

Checking for updates needs an internet connection. It reads only the public release information and sends nothing about you or your setup.

## Where Plug keeps things

| What | Where |
|---|---|
| Your last setup (restored at launch) | `~/Library/Application Support/Plug/settings.json` |
| Presets, one file each | `~/Library/Application Support/Plug/Presets/` |

Preset files can be backed up or copied to another Mac. To start completely fresh, quit Plug and delete `settings.json`.

## Troubleshooting

**I hear nothing.**

- Check **System Settings > Privacy & Security > Screen & System Audio Recording** and allow Plug. Then **STOP** and **START**.
- Check the master knob isn't at the bottom (−∞ dB).
- With **Apps**, check the app you want is ticked and was open when you pressed **START**.
- Check the **OUTPUT** dial points where you're listening.

**Other apps went quiet.** That's capture working: while Plug plays, captured audio is heard only through Plug. Press **STOP**, or quit Plug, and they play normally again.

**Clicks after switching output.** Press **STOP** and **START**.

**An effect's window is too small.** Some plugins don't say how big their interface is, so Plug opens them at a standard size. Drag the window's corner to resize it.

**The MIDI control does nothing.**

- Check the plate shows the control you're moving. If not, click **MIDI LEARN** and move it again.
- Check the controller appears in **Audio MIDI Setup** (Applications > Utilities).

**The Dock still shows an old icon.** Remove Plug from the Dock and drag `build/Plug.app` back in.

**`swift test` says "no such module XCTest".** Point the command line at Xcode, then run the tests again:

```
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

**A build or `swift test` seems stuck.** Quit Plug first. A running `swift run Plug` locks the build folder.
