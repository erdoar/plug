import Foundation
import XCTest
@testable import PlugCore

final class QuickButtonTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("plug-buttons-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testEveryKindRoundTrips() throws {
        let buttons: [QuickButton] = [
            QuickButton(title: "Start", symbol: "power", action: .plug(.toggleRunning)),
            QuickButton(title: "Night", symbol: "moon", action: .plug(.recallPreset(name: "Night"))),
            QuickButton(title: "-6", symbol: "speaker", action: .plug(.setMaster(decibels: -6))),
            QuickButton(title: "Mute", symbol: "speaker.slash", action: .plug(.setMaster(decibels: nil))),
            QuickButton(title: "Delay", symbol: "repeat", action: .plug(.toggleBypass(effectName: "AUDelay"))),
            QuickButton(title: "Scene", symbol: "pianokeys",
                        action: .midi(MIDIMessage(kind: .note, channel: 9, number: 36, value: 100, destination: "IAC Bus 1"))),
            QuickButton(title: "Backup", symbol: "terminal", action: .shell(command: "echo 'hi' | wc -c")),
            QuickButton(title: "Lights", symbol: "lightbulb", action: .shortcut(name: "Studio lights")),
            QuickButton(title: "Docs", symbol: "safari", action: .open(target: "https://example.com")),
            QuickButton(title: "Ask", symbol: "sparkles", action: .claude(prompt: "Suggest an EQ for \"voice\"")),
            QuickButton(title: "Run", symbol: "play", action: .claude(prompt: "/run", folder: "~/plug", access: .edit,
                                                                     allowedTools: "Bash(swift *)")),
        ]
        let url = directory.appendingPathComponent("buttons.json")
        try QuickButtonStore.save(buttons, to: url)
        XCTAssertEqual(QuickButtonStore.load(from: url), buttons)
    }

    func testMissingFileLoadsEmpty() {
        XCTAssertEqual(QuickButtonStore.load(from: directory.appendingPathComponent("none.json")), [])
    }

    func testUnreadableButtonIsSkippedAndTheRestLoad() throws {
        let good = QuickButton(title: "Docs", symbol: "safari", action: .open(target: "https://example.com"))
        let encoded = String(decoding: try JSONEncoder().encode(good), as: UTF8.self)
        let json = "[{\"id\":\"\(UUID().uuidString)\",\"title\":\"Future\",\"symbol\":\"star\",\"showsOutput\":false,\"action\":{\"teleport\":{}}}, \(encoded)]"
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("buttons.json")
        try Data(json.utf8).write(to: url)
        XCTAssertEqual(QuickButtonStore.load(from: url), [good])
    }

    func testOnlyClaudeShowsOutputByDefault() {
        for kind in QuickAction.Kind.allCases {
            XCTAssertEqual(QuickButton.new(kind).showsOutput, kind == .claude, kind.label)
            XCTAssertEqual(QuickButton.new(kind).action.kind, kind)
        }
    }

    func testMIDIWords() {
        XCTAssertEqual(MIDIMessage(kind: .controlChange, channel: 0, number: 7, value: 100).words, [0x20B0_0764])
        XCTAssertEqual(MIDIMessage(kind: .note, channel: 9, number: 36, value: 0).words,
                       [0x2099_2401, 0x2089_2400], "a note on always has some velocity, then its note off")
        XCTAssertEqual(MIDIMessage(kind: .programChange, channel: 15, number: 4, value: 99).words, [0x20CF_0400])
    }

    func testMIDIValuesAreClamped() {
        let message = MIDIMessage(kind: .controlChange, channel: 20, number: 200, value: 255)
        XCTAssertEqual(message.channel, 15)
        XCTAssertEqual(message.number, 127)
        XCTAssertEqual(message.value, 127)
        XCTAssertEqual(message.label, "CC 127 = 127 · CH 16")
    }

    func testPromptsAndNamesAreArgumentsNotCommandText() {
        let prompt = "say \"hi\"; rm -rf ~"
        XCTAssertEqual(QuickAction.claude(prompt: prompt).processArguments(),
                       ["/bin/zsh", "-lc", "claude \"$@\"", "plug", "-p", prompt, "--permission-mode", "dontAsk"])
        XCTAssertEqual(QuickAction.claude(prompt: prompt).processArguments(claudePath: "/opt/homebrew/bin/claude"),
                       ["/opt/homebrew/bin/claude", "-p", prompt, "--permission-mode", "dontAsk"])
        XCTAssertEqual(QuickAction.claude(prompt: "/run", access: .edit, allowedTools: " Bash(swift *),Read ")
                           .processArguments(claudePath: "/c"),
                       ["/c", "-p", "/run", "--permission-mode", "acceptEdits", "--allowedTools", "Bash(swift *),Read"])
        XCTAssertEqual(QuickAction.claude(prompt: "/run", allowedTools: "  ").processArguments(claudePath: "/c"),
                       ["/c", "-p", "/run", "--permission-mode", "dontAsk"], "blank allowed tools are left out")
        XCTAssertEqual(QuickAction.shortcut(name: "A; B").processArguments(), ["/usr/bin/shortcuts", "run", "A; B"])
        XCTAssertEqual(QuickAction.shell(command: "ls ~").processArguments(), ["/bin/zsh", "-lc", "ls ~"])
        XCTAssertNil(QuickAction.open(target: "https://example.com").processArguments())
        XCTAssertEqual(QuickAction.claudeLocations(home: "/Users/a").first, "/Users/a/.local/bin/claude")
    }

    func testProblems() {
        XCTAssertNotNil(QuickAction.shell(command: "  ").problem)
        XCTAssertNotNil(QuickAction.claude(prompt: "\n").problem)
        XCTAssertNotNil(QuickAction.plug(.recallPreset(name: "")).problem)
        XCTAssertNil(QuickAction.plug(.setMaster(decibels: nil)).problem)
        XCTAssertNil(QuickAction.shortcut(name: "Lights").problem)
    }

    /// Ask Claude buttons saved before the folder and access settings
    /// existed still load, with those unset.
    func testOlderClaudeButtonStillLoads() throws {
        let id = UUID()
        let json = "[{\"id\":\"\(id.uuidString)\",\"title\":\"Ask\",\"symbol\":\"sparkles\",\"showsOutput\":true,\"action\":{\"claude\":{\"prompt\":\"Hello\"}}}]"
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("buttons.json")
        try Data(json.utf8).write(to: url)
        let loaded = QuickButtonStore.load(from: url)
        XCTAssertEqual(loaded, [QuickButton(id: id, title: "Ask", symbol: "sparkles", action: .claude(prompt: "Hello"),
                                            showsOutput: true)])
        XCTAssertNil(loaded.first?.action.workingFolder)
    }

    func testWorkingFolder() {
        XCTAssertEqual(QuickAction.claude(prompt: "/run", folder: " ~/plug ").workingFolder, "~/plug")
        XCTAssertNil(QuickAction.claude(prompt: "/run", folder: " ").workingFolder)
        XCTAssertNil(QuickAction.shell(command: "ls").workingFolder)
    }

    func testSearchPathPutsInstallFoldersFirstWithoutRepeats() {
        XCTAssertEqual(QuickAction.searchPath(home: "/Users/a", current: "/usr/bin:/bin:/usr/sbin:/sbin"),
                       "/Users/a/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin")
        XCTAssertEqual(QuickAction.searchPath(home: "/h", current: "/custom::/opt/homebrew/bin"),
                       "/h/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/custom:/usr/bin:/bin:/usr/sbin:/sbin")
        XCTAssertTrue(QuickAction.searchPath(home: "/h", current: nil).hasSuffix("/usr/bin:/bin:/usr/sbin:/sbin"))
    }
}
