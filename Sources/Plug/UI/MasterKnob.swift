import PlugCore
import SwiftUI

/// The post-effects master volume: a large bakelite knob turned by dragging
/// up and down, with its level on a tuning scale above and a brass MIDI
/// Learn plate below.
struct MasterKnob: View {
    @ObservedObject var model: HostModel
    @State private var dragStart: Double?

    var body: some View {
        VStack(spacing: 7) {
            TuningScale(reading: MasterVolume.label(forPosition: model.masterPosition),
                        position: model.masterPosition)
            DialKnob(angle: .degrees(-135 + 270 * model.masterPosition), size: 84, animated: dragStart == nil)
                .contentShape(Circle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            let start = dragStart ?? model.masterPosition
                            if dragStart == nil { dragStart = start }
                            model.setMasterPosition(start - drag.translation.height / 200)
                        }
                        .onEnded { _ in
                            dragStart = nil
                            model.saveSettings()
                        }
                )
                .help("Drag up or down to set the master volume")
                .accessibilityElement()
                .accessibilityLabel("Master volume")
                .accessibilityValue(MasterVolume.label(forPosition: model.masterPosition))
                .accessibilityAdjustableAction { direction in
                    let step = direction == .increment ? 0.05 : -0.05
                    model.setMasterPosition(model.masterPosition + step)
                    model.saveSettings()
                }
            HStack(spacing: 6) {
                EngravedLabel(text: "MASTER")
                learnPlate
            }
        }
    }

    private var learnPlate: some View {
        Button {
            model.toggleMIDILearn()
        } label: {
            Text(model.isLearningMIDI ? "MOVE A CONTROL" : (model.masterMIDI?.label ?? "MIDI LEARN"))
                .font(.system(size: 9, weight: .bold, design: .serif))
                .foregroundStyle(Color(red: 0.25, green: 0.15, blue: 0.05))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(LinearGradient(colors: [Color(red: 0.93, green: 0.8, blue: 0.5), Color(red: 0.66, green: 0.5, blue: 0.24)],
                                                  startPoint: .top, endPoint: .bottom))
                )
                .overlay(Capsule().strokeBorder(Color(red: 0.4, green: 0.28, blue: 0.1).opacity(0.6), lineWidth: 1))
                .opacity(model.isLearningMIDI ? 0.6 : 1)
                .animation(model.isLearningMIDI ? .easeInOut(duration: 0.5).repeatForever() : .default,
                           value: model.isLearningMIDI)
        }
        .buttonStyle(PressableButtonStyle())
        .help(model.isLearningMIDI
              ? "Move a knob or fader on your MIDI controller, or click to cancel"
              : "Click, then move a knob or fader on your MIDI controller to control the master volume")
        .contextMenu {
            if model.masterMIDI != nil {
                Button("Forget MIDI control") { model.forgetMIDI() }
            }
        }
    }
}
