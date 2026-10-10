import PlugCore
import SwiftUI

struct ContentView: View {
    @ObservedObject var model: HostModel
    /// Whether the drawer below the board is open; remembered between launches.
    @AppStorage("drawerOpen") private var isDrawerOpen = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            topPanel

            if isDrawerOpen {
                drawer
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if let message = model.errorMessage {
                Text(message).foregroundStyle(.red)
            }

            PresetBar(model: model, isDrawerOpen: $isDrawerOpen)
        }
        .padding()
        .frame(minWidth: 900)
    }

    // MARK: - Drawer

    /// Everything below the board: capture notes, the app list and the
    /// effect chain. The window grows and shrinks with it.
    private var drawer: some View {
        VStack(alignment: .leading, spacing: 12) {
            if model.input == .systemAudio {
                Text("While Plug runs, other apps play only through Plug. The first time, macOS asks to allow System Audio Recording. This needs the app built with scripts/bundle.sh.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if model.input == .apps {
                HStack {
                    Text("While Plug runs, the ticked apps play only through Plug; everything else plays normally. Apps opened later join at the next Start.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        model.refreshAudioApps()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Refresh the app list")
                }
                if model.audioApps.isEmpty {
                    Text("No apps with audio found. Play something, then refresh.")
                        .foregroundStyle(.secondary)
                }
                ForEach(model.audioApps) { app in
                    Toggle(isOn: Binding(
                        get: { model.capturedApps.contains(app.id) },
                        set: { model.setApp(app.id, captured: $0) }
                    )) {
                        HStack {
                            Text(app.name)
                            if app.isPlaying {
                                Text("playing")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            List {
                ForEach(model.chain.slots) { slot in
                    HStack {
                        Text(slot.name)
                        Spacer()
                        Toggle("Bypass", isOn: Binding(
                            get: { slot.isBypassed },
                            set: { model.setBypassed($0, slotID: slot.id) }
                        ))
                        Button {
                            model.openControls(slotID: slot.id)
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                        .buttonStyle(.borderless)
                        .help("Show the effect's controls")
                        Button {
                            model.removeSlot(id: slot.id)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .help("Remove effect")
                    }
                }
                .onMove { source, destination in
                    model.moveSlots(from: source, to: destination)
                }
            }
            .frame(minHeight: 240)

        }
    }

    // MARK: - Top panel

    private static let inputChoices: [(value: InputSource, label: String)] = [
        (.testTone, "Test tone"),
        (.systemAudio, "System audio"),
        (.apps, "Apps"),
    ]

    private var topPanel: some View {
        HStack(alignment: .center, spacing: 20) {
            LampButton(title: "START", color: Color(red: 0.13, green: 0.66, blue: 0.24), isLit: model.isRunning) {
                if !model.isRunning { model.toggleEngine() }
            }
            LampButton(title: "STOP", color: Color(red: 0.82, green: 0.12, blue: 0.08), isLit: !model.isRunning) {
                if model.isRunning { model.toggleEngine() }
            }
            MasterKnob(model: model)
            Spacer(minLength: 12)
            inputDial
            outputDial
            addDial
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(PineBoard())
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.35), radius: 6, y: 3)
    }

    private var inputDial: some View {
        let choices = Self.inputChoices
        let index = choices.firstIndex { $0.value == model.input }
        return RadioDial(title: "INPUT",
                         reading: index.map { choices[$0].label } ?? "",
                         position: dialPosition(of: index, count: choices.count)) { close in
            DialChoices(options: choices, selection: model.input) { source in
                model.selectInput(source)
                close()
            }
            .padding(14)
            .frame(minWidth: 200)
        }
    }

    private var outputDial: some View {
        let devices = model.outputDevices
        let index = devices.firstIndex { $0.id == model.selectedOutputID }
        return RadioDial(title: "OUTPUT",
                         reading: index.map { devices[$0].name } ?? "No device",
                         position: dialPosition(of: index, count: devices.count)) { close in
            VStack(alignment: .leading, spacing: 10) {
                ScrollView {
                    DialChoices(options: devices.map { (value: $0.id, label: $0.name) },
                                selection: model.selectedOutputID) { deviceID in
                        model.selectOutput(deviceID)
                        close()
                    }
                }
                .frame(maxHeight: 320)
                Divider()
                Button("Refresh devices") {
                    model.refreshOutputDevices()
                }
            }
            .padding(14)
            .frame(minWidth: 240)
        }
    }

    private var addDial: some View {
        RadioDial(title: "ADD",
                  reading: model.chain.slots.isEmpty ? "Add an effect" : "\(model.chain.slots.count) in chain",
                  position: dialPosition(of: min(model.chain.slots.count, 6), count: 7)) { close in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if model.effectGroups.isEmpty {
                        Text("No Audio Unit effects found")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(model.effectGroups) { group in
                        Text(group.manufacturer)
                            .font(.headline)
                        ForEach(group.effects) { effect in
                            Button {
                                model.addEffect(effect)
                                close()
                            } label: {
                                Text(effect.name)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 10)
                        }
                    }
                }
                .padding(14)
            }
            .frame(minWidth: 260, maxHeight: 420)
        }
    }
}
