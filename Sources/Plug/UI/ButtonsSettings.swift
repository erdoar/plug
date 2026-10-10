import AppKit
import PlugCore
import PlugEngine
import SwiftUI

/// Settings > Buttons: make, order and set up the menu bar buttons. The list
/// on the left, the selected button's details on the right. Every change is
/// saved as it is made.
struct ButtonsSettings: View {
    @ObservedObject var buttons: QuickButtonsModel
    @ObservedObject var host: HostModel
    @State private var selection: UUID?

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                List(selection: $selection) {
                    ForEach(buttons.buttons) { button in
                        Label(button.title.isEmpty ? "Untitled" : button.title, systemImage: button.symbol)
                            .tag(button.id)
                    }
                    .onMove { buttons.move(fromOffsets: $0, toOffset: $1) }
                }
                Divider()
                HStack(spacing: 2) {
                    Menu {
                        ForEach(QuickAction.Kind.allCases) { kind in
                            Button(kind.label) {
                                selection = buttons.add(kind).id
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .menuIndicator(.hidden)
                    .fixedSize()
                    .help("Add a button")
                    Button {
                        if let selection {
                            buttons.remove(id: selection)
                            self.selection = buttons.buttons.first?.id
                        }
                    } label: {
                        Image(systemName: "minus")
                    }
                    .disabled(selection == nil)
                    .help("Remove the selected button")
                    Spacer()
                }
                .buttonStyle(.borderless)
                .padding(6)
            }
            .frame(width: 200)
            Divider()
            Group {
                if let selection, let binding = binding(for: selection) {
                    ButtonEditor(button: binding, buttons: buttons, host: host)
                        .id(selection)
                } else {
                    VStack(spacing: 8) {
                        Text(buttons.buttons.isEmpty ? "No buttons yet" : "Choose a button")
                            .font(.headline)
                        Text("Click + to add one. Buttons appear under Plug's icon in the menu bar, in this order. Drag to reorder.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(30)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 640, height: 440)
        .onAppear {
            if selection == nil {
                selection = buttons.buttons.first?.id
            }
        }
    }

    private func binding(for id: UUID) -> Binding<QuickButton>? {
        guard let current = buttons.buttons.first(where: { $0.id == id }) else { return nil }
        return Binding(get: { buttons.buttons.first { $0.id == id } ?? current },
                       set: { buttons.update($0) })
    }
}

/// The details of one button.
private struct ButtonEditor: View {
    @Binding var button: QuickButton
    @ObservedObject var buttons: QuickButtonsModel
    @ObservedObject var host: HostModel

    private static let suggestedSymbols = [
        "power", "play.fill", "stop.fill", "speaker.wave.2.fill", "speaker.slash.fill", "slider.horizontal.3",
        "pianokeys", "music.note", "terminal", "square.stack.3d.up", "link", "folder", "sparkles", "star.fill",
        "lightbulb.fill", "moon.fill", "headphones", "mic.fill",
    ]

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $button.title)
                LabeledContent("Icon") {
                    HStack {
                        Image(systemName: button.symbol)
                            .frame(width: 20)
                        TextField("SF Symbol name", text: $button.symbol)
                            .labelsHidden()
                    }
                }
                LabeledContent("") {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(24)), count: 9), spacing: 6) {
                        ForEach(Self.suggestedSymbols, id: \.self) { symbol in
                            Button {
                                button.symbol = symbol
                            } label: {
                                Image(systemName: symbol)
                                    .frame(width: 22, height: 22)
                                    .background(button.symbol == symbol ? Color.accentColor.opacity(0.25) : .clear,
                                                in: RoundedRectangle(cornerRadius: 4))
                            }
                            .buttonStyle(.plain)
                            .help(symbol)
                        }
                    }
                }
            }
            Section {
                Picker("Action", selection: kindBinding) {
                    ForEach(QuickAction.Kind.allCases) { kind in
                        Text(kind.label).tag(kind)
                    }
                }
                ActionFields(action: $button.action, host: host)
                Toggle("Show the result in a window", isOn: $button.showsOutput)
                    .disabled(button.action.processArguments() == nil)
            }
            Section {
                HStack {
                    if let problem = button.action.problem {
                        Label(problem, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                    Spacer()
                    Button(buttons.running.contains(button.id) ? "Stop" : "Try It") {
                        buttons.run(button)
                    }
                    .disabled(button.action.problem != nil)
                }
                if let message = buttons.errorMessage {
                    Text(message)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
    }

    /// Changing the kind starts the action afresh, and swaps the icon and the
    /// result setting too if they were still the old kind's defaults.
    private var kindBinding: Binding<QuickAction.Kind> {
        Binding(get: { button.action.kind }, set: { kind in
            let old = button.action.kind
            guard kind != old else { return }
            var updated = button
            updated.action = kind.blankAction
            if updated.symbol == old.defaultSymbol {
                updated.symbol = kind.defaultSymbol
            }
            if updated.title == old.label {
                updated.title = kind.label
            }
            updated.showsOutput = kind == .claude
            button = updated
        })
    }
}

/// The fields for each kind of action.
private struct ActionFields: View {
    @Binding var action: QuickAction
    @ObservedObject var host: HostModel

    var body: some View {
        switch action {
        case .plug(let command):
            PlugCommandFields(command: Binding(get: { command }, set: { action = .plug($0) }), host: host)
        case .midi(let message):
            MIDIFields(message: Binding(get: { message }, set: { action = .midi($0) }))
        case .shell(let command):
            VStack(alignment: .leading, spacing: 4) {
                Text("Command")
                TextEditor(text: Binding(get: { command }, set: { action = .shell(command: $0) }))
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 70)
                Text("Runs in zsh from your home folder, like a line typed in Terminal.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .shortcut(let name):
            TextField("Shortcut name", text: Binding(get: { name }, set: { action = .shortcut(name: $0) }))
            Text("The name exactly as it appears in the Shortcuts app.")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .open(let target):
            HStack {
                TextField("Web address or path", text: Binding(get: { target }, set: { action = .open(target: $0) }))
                Button("Choose…") {
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = true
                    panel.treatsFilePackagesAsDirectories = false
                    if panel.runModal() == .OK, let url = panel.url {
                        action = .open(target: url.path)
                    }
                }
            }
        case let .claude(prompt, folder, access, allowedTools):
            VStack(alignment: .leading, spacing: 4) {
                Text("Prompt")
                TextEditor(text: Binding(get: { prompt },
                                         set: { action = .claude(prompt: $0, folder: folder, access: access, allowedTools: allowedTools) }))
                    .frame(minHeight: 90)
                Text("Runs Claude Code on this Mac with your own sign-in. Start with / to run a slash command or skill, like /run.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                TextField("Folder", text: Binding(get: { folder ?? "" },
                                                  set: { action = .claude(prompt: prompt, folder: $0, access: access, allowedTools: allowedTools) }),
                          prompt: Text("Home folder"))
                Button("Choose…") {
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = true
                    panel.canChooseFiles = false
                    if panel.runModal() == .OK, let url = panel.url {
                        action = .claude(prompt: prompt, folder: url.path, access: access, allowedTools: allowedTools)
                    }
                }
            }
            Text("Claude starts here, so it uses this project's commands, skills and CLAUDE.md.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker("Claude may", selection: Binding(get: { access ?? .answer },
                                                    set: { action = .claude(prompt: prompt, folder: folder, access: $0, allowedTools: allowedTools) })) {
                ForEach(ClaudeAccess.allCases) { Text($0.label).tag($0) }
            }
            TextField("Also allow", text: Binding(get: { allowedTools ?? "" },
                                                  set: { action = .claude(prompt: prompt, folder: folder, access: access, allowedTools: $0) }),
                      prompt: Text("e.g. Bash(swift test),Bash(scripts/bundle.sh)"))
            Text("Nobody is there to approve anything, so Claude is refused whatever this doesn't allow. Name commands it may run, separated by commas.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct PlugCommandFields: View {
    @Binding var command: PlugCommand
    @ObservedObject var host: HostModel

    private enum Choice: String, CaseIterable, Identifiable {
        case toggle = "Start or Stop", start = "Start", stop = "Stop"
        case preset = "Recall a preset", master = "Set the master level", bypass = "Bypass an effect"
        var id: String { rawValue }
    }

    var body: some View {
        Picker("Control", selection: choiceBinding) {
            ForEach(Choice.allCases) { Text($0.rawValue).tag($0) }
        }
        switch command {
        case .recallPreset(let name):
            Picker("Preset", selection: Binding(get: { name }, set: { command = .recallPreset(name: $0) })) {
                Text("Choose…").tag("")
                ForEach(withCurrent(host.presetNames, name), id: \.self) { Text($0).tag($0) }
            }
        case .setMaster(let decibels):
            Toggle("Mute", isOn: Binding(get: { decibels == nil },
                                         set: { command = .setMaster(decibels: $0 ? nil : 0) }))
            if let decibels {
                Stepper(value: Binding(get: { decibels }, set: { command = .setMaster(decibels: $0) }),
                        in: -40...MasterVolume.maximumBoost, step: 1) {
                    Text("Level: \(decibels == 0 ? "0 dB" : String(format: "%+.0f dB", decibels))")
                        .monospacedDigit()
                }
            }
        case .toggleBypass(let effectName):
            Picker("Effect", selection: Binding(get: { effectName }, set: { command = .toggleBypass(effectName: $0) })) {
                Text("Choose…").tag("")
                ForEach(withCurrent(host.chain.slots.map(\.name), effectName), id: \.self) { Text($0).tag($0) }
            }
            Text("Each click switches the first effect with this name between bypassed and on.")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .toggleRunning, .start, .stop:
            EmptyView()
        }
    }

    /// The choices, plus the saved one if it's no longer there, so the
    /// picker can still show it.
    private func withCurrent(_ names: [String], _ current: String) -> [String] {
        var unique: [String] = []
        for name in names where !unique.contains(name) {
            unique.append(name)
        }
        if !current.isEmpty, !unique.contains(current) {
            unique.append(current)
        }
        return unique
    }

    private var choiceBinding: Binding<Choice> {
        Binding(get: {
            switch command {
            case .toggleRunning: return .toggle
            case .start: return .start
            case .stop: return .stop
            case .recallPreset: return .preset
            case .setMaster: return .master
            case .toggleBypass: return .bypass
            }
        }, set: { choice in
            switch choice {
            case .toggle: command = .toggleRunning
            case .start: command = .start
            case .stop: command = .stop
            case .preset: command = .recallPreset(name: host.presetNames.first ?? "")
            case .master: command = .setMaster(decibels: 0)
            case .bypass: command = .toggleBypass(effectName: host.chain.slots.first?.name ?? "")
            }
        })
    }
}

private struct MIDIFields: View {
    @Binding var message: MIDIMessage
    @State private var destinations = MIDIOutput.destinationNames()

    var body: some View {
        Picker("Message", selection: $message.kind) {
            ForEach(MIDIMessage.Kind.allCases) { Text($0.label).tag($0) }
        }
        Picker("Send to", selection: $message.destination) {
            Text("All MIDI outputs").tag(String?.none)
            ForEach(destinationChoices, id: \.self) { Text($0).tag(String?.some($0)) }
        }
        Stepper("Channel: \(Int(message.channel) + 1)", value: number(\.channel, offset: 1), in: 1...16)
        switch message.kind {
        case .controlChange:
            Stepper("Controller: \(message.number)", value: number(\.number), in: 0...127)
            Stepper("Value: \(message.value)", value: number(\.value), in: 0...127)
        case .note:
            Stepper("Note: \(message.number)", value: number(\.number), in: 0...127)
            Stepper("Velocity: \(max(message.value, 1))", value: number(\.value), in: 1...127)
        case .programChange:
            Stepper("Program: \(Int(message.number) + 1)", value: number(\.number, offset: 1), in: 1...128)
        }
        Text("To reach another app on this Mac, turn on the IAC Driver in Audio MIDI Setup and choose its bus here.")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var destinationChoices: [String] {
        guard let current = message.destination, !destinations.contains(current) else { return destinations }
        return destinations + [current]
    }

    /// A field of the message as an Int for a stepper, shown `offset` higher
    /// than it is stored (channels and programs count from 1).
    private func number(_ keyPath: WritableKeyPath<MIDIMessage, UInt8>, offset: Int = 0) -> Binding<Int> {
        Binding(get: { Int(message[keyPath: keyPath]) + offset },
                set: { message[keyPath: keyPath] = UInt8(min(max($0 - offset, 0), 127)) })
    }
}
