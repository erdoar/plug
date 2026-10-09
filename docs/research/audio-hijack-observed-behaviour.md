# Observed behaviour: Audio Hijack 4.6.0 (reference only)

Source: the product's own in-app tour and about pages, as shipped with version 4.6.0. Written in our own words. No code, strings or assets are reproduced here. Used only to understand what the product does from the user's side; it does not define the Plug implementation.

## Concepts the product exposes
- **Sessions**: saved, reusable collections of capture settings. They save automatically. Templates are offered as starting points.
- **Pipelines**: a session is a chain of blocks. The tour's basic example is an application source, a recorder, and an output device, so the audio is recorded and also played to headphones.
- **Effects**: built-in equalisers and compressors, plus support for Audio Unit plugins in the chain.
- **Recordings**: each session has a recordings view for the captured audio, with some editing.
- **Other features mentioned**: menu-bar control, timers, live streaming.

## Relevance to Plug
- Plug's scope is an AU plugin host between apps or system audio and the output device. The concepts that matter most here are the effect chain and the per-device output path.
- Session persistence, recording, streaming and timers are outside Plug's current scope.

## Not established by this note
- How the product captures audio internally, which APIs it uses, and its file formats. These are not visible from the tour and must not be inferred from its binary here.
- Any behaviour that needs a running copy of the app. Those observations need to be made on a Mac and recorded here, in our own words.
