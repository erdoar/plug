import AppKit
import Combine
import Foundation
import PlugCore
import PlugEngine
import SwiftUI

/// The menu bar buttons: keeps the list the person set up, saves it, and
/// runs a button's action when it is clicked.
@MainActor
final class QuickButtonsModel: ObservableObject {
    @Published private(set) var buttons: [QuickButton]
    /// Buttons whose command, shortcut or Claude prompt is still running.
    @Published private(set) var running: Set<UUID> = []
    /// The last thing that went wrong, shown in the menu bar panel.
    @Published var errorMessage: String?

    private let host: HostModel
    private let outputWindows = ButtonOutputWindows()
    private var processes: [UUID: Process] = [:]
    private lazy var midiOutput: MIDIOutput? = try? MIDIOutput()

    private static let fileURL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Plug")
        .appendingPathComponent("buttons.json")

    init(host: HostModel) {
        self.host = host
        buttons = QuickButtonStore.load(from: Self.fileURL)
    }

    // MARK: - Editing

    func add(_ kind: QuickAction.Kind) -> QuickButton {
        let button = QuickButton.new(kind)
        buttons.append(button)
        save()
        return button
    }

    func update(_ button: QuickButton) {
        guard let index = buttons.firstIndex(where: { $0.id == button.id }), buttons[index] != button else { return }
        buttons[index] = button
        save()
    }

    func remove(id: UUID) {
        buttons.removeAll { $0.id == id }
        save()
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        buttons.move(fromOffsets: source, toOffset: destination)
        save()
    }

    private func save() {
        do {
            try QuickButtonStore.save(buttons, to: Self.fileURL)
        } catch {
            errorMessage = "Couldn't save the buttons: \(error.localizedDescription)"
        }
    }

    // MARK: - Running

    /// Runs the button's action. Clicking a button that is still running
    /// stops it instead.
    func run(_ button: QuickButton) {
        if let process = processes[button.id] {
            process.terminate()
            return
        }
        errorMessage = nil
        if let problem = button.action.problem {
            errorMessage = "\(button.title): \(problem)"
            return
        }
        switch button.action {
        case .plug(let command):
            runPlugCommand(command, title: button.title)
        case .midi(let message):
            guard let midiOutput else {
                errorMessage = "MIDI isn't available."
                return
            }
            if !midiOutput.send(message) {
                errorMessage = "\(button.title): the MIDI output \u{201C}\(message.destination ?? "")\u{201D} isn't connected."
            }
        case .open(let target):
            open(target, title: button.title)
        case .shell, .shortcut, .claude:
            let claudePath = QuickAction.claudeLocations(home: NSHomeDirectory())
                .first { FileManager.default.isExecutableFile(atPath: $0) }
            guard let arguments = button.action.processArguments(claudePath: claudePath) else { return }
            launch(arguments, for: button)
        }
    }

    private func runPlugCommand(_ command: PlugCommand, title: String) {
        switch command {
        case .toggleRunning:
            host.toggleEngine()
        case .start:
            if !host.isRunning { host.toggleEngine() }
        case .stop:
            if host.isRunning { host.toggleEngine() }
        case .recallPreset(let name):
            host.recallPreset(name)
        case .setMaster(let decibels):
            host.setMasterPosition(MasterVolume.position(forDecibels: decibels))
            host.saveSettings()
        case .toggleBypass(let effectName):
            if !host.toggleBypass(effectNamed: effectName) {
                errorMessage = "\(title): there's no \u{201C}\(effectName)\u{201D} in the effects."
            }
        }
    }

    private func open(_ target: String, title: String) {
        let trimmed = target.trimmingCharacters(in: .whitespaces)
        let expanded = (trimmed as NSString).expandingTildeInPath
        let url: URL?
        if expanded.hasPrefix("/") {
            url = URL(fileURLWithPath: expanded)
        } else if let parsed = URL(string: trimmed), parsed.scheme != nil {
            url = parsed
        } else {
            url = URL(string: "https://" + trimmed)
        }
        guard let url, NSWorkspace.shared.open(url) else {
            errorMessage = "\(title): couldn't open \u{201C}\(trimmed)\u{201D}."
            return
        }
    }

    /// Starts the program off the main thread and collects what it prints.
    /// Output and errors share one pipe, read to the end before waiting, so
    /// a chatty program can't fill the pipe and stall.
    private func launch(_ arguments: [String], for button: QuickButton) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: arguments[0])
        process.arguments = Array(arguments.dropFirst())
        process.currentDirectoryURL = FileManager.default.homeDirectoryForCurrentUser
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        process.standardInput = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            errorMessage = "\(button.title): couldn't start (\(error.localizedDescription))."
            return
        }
        processes[button.id] = process
        running.insert(button.id)
        Task.detached {
            let data = (try? pipe.fileHandleForReading.readToEnd()) ?? Data()
            process.waitUntilExit()
            let output = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            let status = process.terminationStatus
            let wasStopped = process.terminationReason == .uncaughtSignal
            await MainActor.run {
                self.finished(button, status: status, output: output, wasStopped: wasStopped)
            }
        }
    }

    private func finished(_ button: QuickButton, status: Int32, output: String, wasStopped: Bool) {
        processes[button.id] = nil
        running.remove(button.id)
        if wasStopped {
            return
        }
        if status == 0 {
            if button.showsOutput {
                outputWindows.show(title: button.title, text: output.isEmpty ? "(Nothing was printed.)" : output)
            }
            return
        }
        var message = output.isEmpty ? "It ended with error \(status)." : output
        if status == 127, button.action.kind == .claude {
            message = "Plug couldn't find Claude Code. Install it, run `claude` once in Terminal to sign in, then try again."
        }
        errorMessage = "\(button.title) didn't finish."
        outputWindows.show(title: "\(button.title) didn't finish", text: message)
    }
}
