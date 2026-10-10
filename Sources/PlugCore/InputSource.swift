/// Where the audio going into the effect chain comes from.
public enum InputSource: String, Hashable, CaseIterable, Codable {
    /// A quiet 440 Hz sine, for trying effects without other audio.
    case testTone
    /// Everything the Mac plays, except Plug itself.
    case systemAudio
    /// Only the apps the user picked (see `AppKey`).
    case apps
}
