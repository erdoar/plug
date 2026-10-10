# Plug

Plug runs the sound your Mac plays through Audio Unit effects, and plays the result to the output you choose. It needs macOS 14.2 or later.

## Install

1. Open the Plug disk image and drag **Plug** onto **Applications**.
2. The first time, **right-click Plug** in Applications and choose **Open**, then **Open** again. After that, open it as usual.
3. When you first press **START**, macOS asks to allow **System Audio Recording**. Allow it.

## Play

- **START** (green) plays. **STOP** (red) stops. The lit lamp shows which is active.
- While Plug plays, the sound it captures is heard only through Plug. Press **STOP** and other apps play normally again.
- Keep your volume low at first. The master knob can boost.

## Choose what goes in: INPUT

Click the **INPUT** knob and pick one:

- **Test tone**: a quiet tone, for trying effects.
- **System audio**: everything your Mac plays.
- **Apps**: only the apps you tick in the drawer. Click the arrow to refresh the list. An app opened while Plug is playing joins at the next **STOP** and **START**.

## Choose where it plays: OUTPUT

Click the **OUTPUT** knob and pick a speaker, headphones or interface. Choose **Refresh devices** if one is missing.

## Effects

- **Add:** click the **ADD** knob and pick an effect.
- **Order:** drag effects up or down in the drawer. Sound passes through them top to bottom.
- **Bypass:** switches an effect off but keeps its settings.
- **Sliders icon:** opens the effect's controls.
- **Bin:** removes the effect.

The worn handle in the bottom strip opens and closes the drawer.

## Master volume

- Drag the **MASTER** knob up or down.
- The **bent tack** marks 0 dB. Click the tack to return there.
- Below the tack turns the level down. Above it boosts, up to +10 dB. Too much boost distorts.

## MIDI control

1. Click **MIDI LEARN**.
2. Move a knob or fader on your MIDI controller.
3. That control now turns the master knob.

Right-click **MIDI LEARN** to forget the control.

## Buttons

Add your own buttons to the menu bar panel. Each one does a single thing when you click it.

1. Click the VU meter in the menu bar, then **Add Buttons…** (or choose **Plug > Settings…**).
2. Click **+** and pick what the button does. Give it a name and an icon.
3. Click **Try It** to test it. Every change is saved as you make it.

A button can:

- **Plug control:** Start or Stop, recall a preset, set the master level, or bypass an effect.
- **Send MIDI:** a control change, note or program change, to one MIDI output or all of them. To reach another app on this Mac, turn on the IAC Driver in Audio MIDI Setup.
- **Run command:** a Terminal command, run from your home folder.
- **Run shortcut:** any shortcut from the Shortcuts app, by name.
- **Open:** a web address, file, folder or app.
- **Ask Claude:** sends your prompt to Claude Code on this Mac and shows the reply. Install Claude Code and run `claude` once in Terminal to sign in first.
  - Start the prompt with **/** to run a slash command or skill, such as `/run`.
  - **Folder** is where Claude starts, so it uses that project's commands, skills and notes. Leave it empty for your home folder.
  - **Claude may** sets what it can do there: read and answer only, or also edit files.
  - **Also allow** names commands it may run, separated by commas, such as `Bash(swift test),Bash(scripts/bundle.sh)`. Nobody is there to approve anything, so Claude is refused whatever isn't allowed.

Tick **Show the result in a window** to see what a command printed. Click a button while it's still running to stop it. Drag buttons in the list to change their order, and select one and click **–** (or press Delete, or right-click it and choose **Delete**) to remove it.

## Presets

- **SAVE** stores everything: input, apps, output, effects with their settings, and the master level.
- Click the small **preset knob** to recall a preset, or click the bin beside it to delete it.

## Quick controls

- **Dock icon, right-click:** Start or Stop, and set the master level.
- **VU meter in the menu bar:** a master volume slider, your buttons, Start or Stop, Open Plug, and Quit.

Closing the window keeps Plug playing. Quit Plug to stop it completely.

## Help and updates

- **Help > Plug Help** opens this guide.
- **Plug > Check for Updates…** tells you if a newer Plug is available.

## If you hear nothing

- Allow Plug in **System Settings > Privacy & Security > Screen & System Audio Recording**, then press **STOP** and **START**.
- Check the **MASTER** knob isn't turned all the way down.
- Check **OUTPUT** is set to where you're listening.
- With **Apps**, check the app is ticked and was open when you pressed **START**.
