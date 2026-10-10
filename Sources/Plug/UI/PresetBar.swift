import SwiftUI

/// The strip of pine at the bottom of the window: the current preset on a
/// tuning scale on the left, the drawer handle in the centre, and on the
/// right a small knob that opens the preset list (recall or delete) and a
/// brass plate to save the current setup as a preset.
struct PresetBar: View {
    @ObservedObject var model: HostModel
    @Binding var isDrawerOpen: Bool
    @State private var isListOpen = false
    @State private var isNaming = false
    @State private var newName = ""

    var body: some View {
        let names = model.presetNames
        let index = model.currentPreset.flatMap { names.firstIndex(of: $0) }
        HStack(spacing: 14) {
            EngravedLabel(text: "PRESETS")
            TuningScale(reading: model.currentPreset ?? "No preset",
                        position: dialPosition(of: index, count: names.count),
                        width: 220)
            Spacer()
            Button {
                isListOpen.toggle()
            } label: {
                DialKnob(angle: .degrees(-135 + 270 * dialPosition(of: index, count: names.count)), size: 40)
            }
            .buttonStyle(PressableButtonStyle())
            .help("Recall a preset")
            .accessibilityLabel("Presets")
            .popover(isPresented: $isListOpen, arrowEdge: .top) {
                presetList(names)
            }
            Button {
                newName = model.currentPreset ?? ""
                isNaming = true
            } label: {
                BrassPlateLabel(text: "SAVE")
            }
            .buttonStyle(PressableButtonStyle())
            .help("Save everything as a preset: input, apps, output, effects and their settings, and the master level")
        }
        // The drawer handle sits at the exact centre of the strip.
        .overlay {
            DrawerHandle(isOpen: isDrawerOpen) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isDrawerOpen.toggle()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(PineBoard())
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
        .alert("Save preset", isPresented: $isNaming) {
            TextField("Name", text: $newName)
            Button("Save") {
                model.savePreset(named: newName)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Saves the input, apps, output, effects with their settings, and the master level. Saving with an existing name replaces that preset.")
        }
    }

    private func presetList(_ names: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if names.isEmpty {
                Text("No presets yet. Set things up, then press SAVE.")
                    .foregroundStyle(.secondary)
            }
            ForEach(names, id: \.self) { name in
                HStack {
                    Button {
                        model.recallPreset(name)
                        isListOpen = false
                    } label: {
                        HStack {
                            Image(systemName: name == model.currentPreset ? "largecircle.fill.circle" : "circle")
                            Text(name)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Button {
                        model.deletePreset(name)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .help("Delete this preset")
                }
            }
        }
        .padding(14)
        .frame(minWidth: 240)
    }
}
