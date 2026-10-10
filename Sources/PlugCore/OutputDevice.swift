/// An audio output device: built-in speakers, headphones, an interface.
/// `id` is the Core Audio device ID, valid while the device stays connected;
/// `uid` is stable across reconnects and restarts.
public struct OutputDevice: Identifiable, Hashable {
    public let id: UInt32
    public let uid: String
    public let name: String

    public init(id: UInt32, uid: String, name: String) {
        self.id = id
        self.uid = uid
        self.name = name
    }
}
