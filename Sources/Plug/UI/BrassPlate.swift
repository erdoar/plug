import SwiftUI

/// A small engraved brass plate, used as a label for minor buttons.
struct BrassPlateLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .bold, design: .serif))
            .foregroundStyle(Color(red: 0.25, green: 0.15, blue: 0.05))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(LinearGradient(colors: [Color(red: 0.93, green: 0.8, blue: 0.5), Color(red: 0.66, green: 0.5, blue: 0.24)],
                                              startPoint: .top, endPoint: .bottom))
            )
            .overlay(Capsule().strokeBorder(Color(red: 0.4, green: 0.28, blue: 0.1).opacity(0.6), lineWidth: 1))
    }
}
