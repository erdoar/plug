import SwiftUI

/// A large round illuminated push button with a chrome bezel. Glows when lit.
struct LampButton: View {
    let title: String
    let color: Color
    let isLit: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [color.opacity(isLit ? 1 : 0.5), color.opacity(isLit ? 0.8 : 0.35), .black.opacity(0.55)],
                        center: UnitPoint(x: 0.38, y: 0.32), startRadius: 2, endRadius: 52))
                Circle()
                    .fill(RadialGradient(colors: [.white.opacity(isLit ? 0.55 : 0.25), .clear],
                                         center: UnitPoint(x: 0.35, y: 0.25), startRadius: 0, endRadius: 22))
                Circle()
                    .strokeBorder(LinearGradient(colors: [.white.opacity(0.85), Color(white: 0.45), .black.opacity(0.6)],
                                                 startPoint: .top, endPoint: .bottom),
                                  lineWidth: 5)
                Text(title)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(isLit ? 1 : 0.75))
                    .shadow(color: .black.opacity(0.6), radius: 1, y: 1)
            }
            .frame(width: 84, height: 84)
            .shadow(color: isLit ? color.opacity(0.85) : .black.opacity(0.45), radius: isLit ? 14 : 4, y: isLit ? 0 : 2)
            .animation(.easeOut(duration: 0.2), value: isLit)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(title)
    }
}

/// Sinks slightly while held down.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .brightness(configuration.isPressed ? -0.08 : 0)
    }
}
