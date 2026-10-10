/// Where the audio going into the effect chain comes from.
public enum InputSource: Hashable, CaseIterable {
    /// A quiet 440 Hz sine, for trying effects without other audio.
    case testTone
    /// Everything the Mac plays, except Plug itself.
    case systemAudio
}
