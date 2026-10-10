import SwiftUI

/// An old radio band selector: a backlit tuning scale showing the current
/// choice with a needle, a knurled bakelite knob whose pointer turns to the
/// choice, and an engraved title. Clicking the knob opens the choices.
struct RadioDial<Choices: View>: View {
    let title: String
    let reading: String
    /// Where the needle and pointer sit along the scale, 0...1.
    let position: Double
    @ViewBuilder let choices: (_ close: @escaping () -> Void) -> Choices
    @State private var isOpen = false

    var body: some View {
        VStack(spacing: 7) {
            TuningScale(reading: reading, position: position)
            Button {
                isOpen.toggle()
            } label: {
                DialKnob(angle: .degrees(-135 + 270 * position))
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel("\(title): \(reading)")
            .popover(isPresented: $isOpen, arrowEdge: .bottom) {
                choices { isOpen = false }
            }
            EngravedLabel(text: title)
        }
    }
}

/// Spreads `count` choices evenly along a dial's scale; the middle when
/// nothing is chosen.
func dialPosition(of index: Int?, count: Int) -> Double {
    guard let index, count > 1 else { return 0.5 }
    return Double(index) / Double(count - 1)
}

/// The choices a dial opens: a radio list of labelled values.
struct DialChoices<Value: Hashable>: View {
    let options: [(value: Value, label: String)]
    let selection: Value?
    let onSelect: (Value) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                Button {
                    onSelect(option.value)
                } label: {
                    HStack {
                        Image(systemName: option.value == selection ? "largecircle.fill.circle" : "circle")
                        Text(option.label)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// The backlit cream scale with tick marks, a red needle and the reading.
struct TuningScale: View {
    let reading: String
    let position: Double

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(colors: [Color(red: 1, green: 0.94, blue: 0.74),
                                              Color(red: 0.96, green: 0.80, blue: 0.48)],
                                     startPoint: .top, endPoint: .bottom))
            Canvas { context, size in
                let inset: CGFloat = 8
                for tick in 0...20 {
                    let x = inset + (size.width - 2 * inset) * CGFloat(tick) / 20
                    var line = Path()
                    line.move(to: CGPoint(x: x, y: 3))
                    line.addLine(to: CGPoint(x: x, y: tick % 5 == 0 ? 11 : 7))
                    context.stroke(line, with: .color(Color(red: 0.3, green: 0.18, blue: 0.08).opacity(0.7)), lineWidth: 1)
                }
                let needleX = inset + (size.width - 2 * inset) * position
                var needle = Path()
                needle.move(to: CGPoint(x: needleX, y: 1))
                needle.addLine(to: CGPoint(x: needleX, y: size.height - 1))
                context.stroke(needle, with: .color(Color(red: 0.8, green: 0.1, blue: 0.05).opacity(0.85)), lineWidth: 1.5)
            }
            .animation(.spring(duration: 0.4), value: position)
            Text(reading)
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .foregroundStyle(Color(red: 0.25, green: 0.14, blue: 0.06))
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, 6)
                .padding(.bottom, 4)
        }
        .frame(width: 136, height: 38)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(LinearGradient(colors: [Color(red: 0.95, green: 0.82, blue: 0.5), Color(red: 0.5, green: 0.36, blue: 0.14)],
                                             startPoint: .top, endPoint: .bottom),
                              lineWidth: 2)
        )
        .shadow(color: Color.orange.opacity(0.35), radius: 5)
    }
}

/// A knurled brown bakelite knob with a white pointer.
struct DialKnob: View {
    let angle: Angle

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color(red: 0.40, green: 0.22, blue: 0.11), Color(red: 0.12, green: 0.06, blue: 0.03)],
                                     center: UnitPoint(x: 0.35, y: 0.3), startRadius: 1, endRadius: 42))
            ForEach(0..<40, id: \.self) { ridge in
                Capsule()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 2, height: 6)
                    .offset(y: -27)
                    .rotationEffect(.degrees(Double(ridge) * 9))
            }
            Circle()
                .inset(by: 10)
                .fill(RadialGradient(colors: [Color(red: 0.47, green: 0.27, blue: 0.14), Color(red: 0.2, green: 0.1, blue: 0.05)],
                                     center: UnitPoint(x: 0.4, y: 0.35), startRadius: 1, endRadius: 30))
            Capsule()
                .fill(Color(white: 0.95))
                .frame(width: 3, height: 15)
                .offset(y: -12)
                .rotationEffect(angle)
        }
        .frame(width: 62, height: 62)
        .shadow(color: .black.opacity(0.5), radius: 3, y: 2)
        .animation(.spring(duration: 0.4), value: angle)
    }
}
