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
                .overlay { unityTack }
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

    /// The tack marking 0 dB beside the knob's rim; clicking it returns
    /// the knob to 0 dB.
    private var unityTack: some View {
        let angle = (-135 + 270 * MasterVolume.unityPosition) * Double.pi / 180
        let radius = 84.0 / 2 + 11
        return BentTack()
            .offset(x: radius * sin(angle), y: -radius * cos(angle))
            .onTapGesture {
                model.setMasterPosition(MasterVolume.unityPosition)
                model.saveSettings()
            }
            .help("0 dB. Click to return the master here.")
            .accessibilityElement()
            .accessibilityLabel("Return master to 0 dB")
            .accessibilityAddTraits(.isButton)
    }

    private var learnPlate: some View {
        Button {
            model.toggleMIDILearn()
        } label: {
            BrassPlateLabel(text: model.isLearningMIDI ? "MOVE A CONTROL" : (model.masterMIDI?.label ?? "MIDI LEARN"))
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
