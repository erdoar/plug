import Foundation

/// A button in the menu bar panel that runs one action. People make their
/// own in Plug's settings.
public struct QuickButton: Codable, Equatable, Identifiable {
    public var id: UUID
    public var title: String
    /// An SF Symbol name for the button's icon.
    public var symbol: String
    public var action: QuickAction
    /// Show what the action printed (or Claude's reply) in a window.
    public var showsOutput: Bool

    public init(id: UUID = UUID(), title: String, symbol: String, action: QuickAction, showsOutput: Bool? = nil) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.action = action
        self.showsOutput = showsOutput ?? action.showsOutputByDefault
    }

    /// A new button of the given kind, filled in enough to try.
    public static func new(_ kind: QuickAction.Kind) -> QuickButton {
        QuickButton(title: kind.label, symbol: kind.defaultSymbol, action: kind.blankAction)
    }
}

/// What a button does.
public enum QuickAction: Codable, Equatable {
    case plug(PlugCommand)
    case midi(MIDIMessage)
    case shell(command: String)
    /// A shortcut from the Shortcuts app, by name.
    case shortcut(name: String)
    /// A web address, or the path of a file, folder or app.
    case open(target: String)
    /// A prompt for Claude Code (`claude -p`), using the person's own login.
    /// A prompt starting with "/" runs a slash command or skill. `folder` is
    /// where Claude starts, which decides the project whose commands, skills
    /// and CLAUDE.md it sees (nil is the home folder). `access` says what it
    /// may do there without asking (nil is read and answer only), and
    /// `allowedTools` names further tools in Claude Code's rule syntax, for
    /// example `Bash(swift test)`. Buttons saved before these existed load
    /// with them unset.
    case claude(prompt: String, folder: String? = nil, access: ClaudeAccess? = nil, allowedTools: String? = nil)

    public enum Kind: String, CaseIterable, Identifiable {
        case plug, midi, shell, shortcut, open, claude
        public var id: String { rawValue }

        public var label: String {
            switch self {
            case .plug: return "Plug control"
            case .midi: return "Send MIDI"
            case .shell: return "Run command"
            case .shortcut: return "Run shortcut"
            case .open: return "Open"
            case .claude: return "Ask Claude"
            }
        }

        public var defaultSymbol: String {
            switch self {
            case .plug: return "power"
            case .midi: return "pianokeys"
            case .shell: return "terminal"
            case .shortcut: return "square.stack.3d.up"
            case .open: return "arrow.up.forward.app"
            case .claude: return "sparkles"
            }
        }

        public var blankAction: QuickAction {
            switch self {
            case .plug: return .plug(.toggleRunning)
            case .midi: return .midi(MIDIMessage(kind: .controlChange, channel: 0, number: 1, value: 127))
            case .shell: return .shell(command: "")
            case .shortcut: return .shortcut(name: "")
            case .open: return .open(target: "")
            case .claude: return .claude(prompt: "")
            }
        }
    }

    public var kind: Kind {
        switch self {
        case .plug: return .plug
        case .midi: return .midi
        case .shell: return .shell
        case .shortcut: return .shortcut
        case .open: return .open
        case .claude: return .claude
        }
    }

    /// The folder a Claude action starts in, as typed (it may start with
    /// "~"); nil for other kinds, or to start in the home folder.
    public var workingFolder: String? {
        guard case let .claude(_, folder, _, _) = self,
              let folder = folder?.trimmingCharacters(in: .whitespaces), !folder.isEmpty else { return nil }
        return folder
    }

    var showsOutputByDefault: Bool {
        kind == .claude
    }

    /// The program and arguments that run this action, for the kinds that
    /// run one. Commands run through a login shell so they see much the same
    /// PATH as Terminal (an app launched from the Dock doesn't). Names and
    /// prompts are passed as arguments, never pasted into the command text,
    /// so quotes and other characters in them can't change the command.
    /// `claudePath` is where Claude Code was found (see
    /// `claudeLocations`); without it the shell looks for `claude`.
    public func processArguments(claudePath: String? = nil) -> [String]? {
        switch self {
        case .shell(let command):
            return ["/bin/zsh", "-lc", command]
        case .shortcut(let name):
            return ["/usr/bin/shortcuts", "run", name]
        case let .claude(prompt, _, access, allowedTools):
            var arguments = ["-p", prompt, "--permission-mode", (access ?? .answer).permissionMode]
            if let tools = allowedTools?.trimmingCharacters(in: .whitespaces), !tools.isEmpty {
                arguments += ["--allowedTools", tools]
            }
            if let claudePath {
                return [claudePath] + arguments
            }
            return ["/bin/zsh", "-lc", "claude \"$@\"", "plug"] + arguments
        case .plug, .midi, .open:
            return nil
        }
    }

    /// Where Claude Code's installers put the `claude` command, most likely
    /// first.
    public static func claudeLocations(home: String) -> [String] {
        [
            home + "/.local/bin/claude",
            home + "/.claude/local/claude",
            "/opt/homebrew/bin/claude",
            "/usr/local/bin/claude",
        ]
    }

    /// Why the action can't run as set up, or nil if it can.
    public var problem: String? {
        switch self {
        case .shell(let command) where command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty:
            return "Type a command to run."
        case .shortcut(let name) where name.trimmingCharacters(in: .whitespaces).isEmpty:
            return "Type the name of a shortcut."
        case .open(let target) where target.trimmingCharacters(in: .whitespaces).isEmpty:
            return "Type a web address or choose a file or app."
        case .claude(let prompt, _, _, _) where prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty:
            return "Type a prompt for Claude."
        case .plug(.recallPreset(let name)) where name.isEmpty:
            return "Choose a preset."
        case .plug(.toggleBypass(let name)) where name.isEmpty:
            return "Choose an effect."
        default:
            return nil
        }
    }
}

/// What Claude may do without asking when a button runs it. Nobody is there
/// to approve anything, so whatever needs approval is refused. Tools named in
/// the button's allowed tools are allowed on top of this.
public enum ClaudeAccess: String, Codable, CaseIterable, Identifiable {
    /// Read files in the folder and answer.
    case answer
    /// Also edit files in the folder and run common file commands.
    case edit
    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .answer: return "Read and answer only"
        case .edit: return "Also edit files in the folder"
        }
    }

    /// The value for Claude Code's `--permission-mode`.
    public var permissionMode: String {
        switch self {
        case .answer: return "dontAsk"
        case .edit: return "acceptEdits"
        }
    }
}

/// Plug's own controls, for buttons.
public enum PlugCommand: Codable, Equatable {
    case toggleRunning
    case start
    case stop
    case recallPreset(name: String)
    /// Sets the master level in dB; nil mutes.
    case setMaster(decibels: Double?)
    /// Bypasses the first effect with this name, or brings it back.
    case toggleBypass(effectName: String)
}

/// A MIDI 1.0 message a button sends.
public struct MIDIMessage: Codable, Equatable {
    public enum Kind: String, Codable, CaseIterable, Identifiable {
        case controlChange, note, programChange
        public var id: String { rawValue }

        public var label: String {
            switch self {
            case .controlChange: return "Control change"
            case .note: return "Note"
            case .programChange: return "Program change"
            }
        }
    }

    public var kind: Kind
    /// 0...15 (shown to people as 1...16).
    public var channel: UInt8
    /// The controller, note or program number, 0...127.
    public var number: UInt8
    /// The controller value or note velocity, 0...127. Program changes have none.
    public var value: UInt8
    /// The display name of the MIDI output to send to; nil sends to every output.
    public var destination: String?

    public init(kind: Kind, channel: UInt8, number: UInt8, value: UInt8, destination: String? = nil) {
        self.kind = kind
        self.channel = min(channel, 15)
        self.number = min(number, 127)
        self.value = min(value, 127)
        self.destination = destination
    }

    /// The message as Universal MIDI Packet words (MIDI 1.0 channel voice,
    /// group 0), in the order to send them. A note is a note on followed by
    /// its note off.
    public var words: [UInt32] {
        func word(_ status: UInt8, _ data1: UInt8, _ data2: UInt8) -> UInt32 {
            0x2000_0000 | UInt32(status | (channel & 0xF)) << 16 | UInt32(data1 & 0x7F) << 8 | UInt32(data2 & 0x7F)
        }
        switch kind {
        case .controlChange:
            return [word(0xB0, number, value)]
        case .note:
            return [word(0x90, number, max(value, 1)), word(0x80, number, 0)]
        case .programChange:
            return [word(0xC0, number, 0)]
        }
    }

    /// "CC 7 = 127 · CH 1", "Note 60 · CH 10", "Program 5 · CH 1".
    public var label: String {
        let channelLabel = "CH \(Int(channel) + 1)"
        switch kind {
        case .controlChange: return "CC \(number) = \(value) · \(channelLabel)"
        case .note: return "Note \(number) · \(channelLabel)"
        case .programChange: return "Program \(Int(number) + 1) · \(channelLabel)"
        }
    }
}

/// Reads and writes the buttons as JSON, in their own file: they belong to
/// the person's Mac, not to a setup, so presets don't carry them.
public enum QuickButtonStore {
    /// Empty if the file is missing. A button that can't be read (one saved
    /// by a newer Plug, say) is skipped rather than losing the rest.
    public static func load(from url: URL) -> [QuickButton] {
        guard let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([Lenient].self, from: data) else { return [] }
        return entries.compactMap(\.button)
    }

    public static func save(_ buttons: [QuickButton], to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(buttons).write(to: url, options: .atomic)
    }

    private struct Lenient: Decodable {
        let button: QuickButton?

        init(from decoder: Decoder) throws {
            button = try? QuickButton(from: decoder)
        }
    }
}
