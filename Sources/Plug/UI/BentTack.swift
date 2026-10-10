import SwiftUI

/// A brass drawing pin pushed into the board and bent over: a tilted oval
/// head with its pin bent out from under it into the wood.
struct BentTack: View {
    var body: some View {
        ZStack {
            Path { pin in
                pin.move(to: CGPoint(x: 9, y: 10))
                pin.addLine(to: CGPoint(x: 15, y: 12))
                pin.addLine(to: CGPoint(x: 18, y: 17))
            }
            .stroke(LinearGradient(colors: [Color(white: 0.85), Color(white: 0.4)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
            .shadow(color: .black.opacity(0.35), radius: 0.5, x: 0.5, y: 1)
            Ellipse()
                .fill(RadialGradient(colors: [Color(red: 1, green: 0.92, blue: 0.62),
                                              Color(red: 0.74, green: 0.54, blue: 0.2),
                                              Color(red: 0.4, green: 0.27, blue: 0.09)],
                                     center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0.5, endRadius: 8))
                .frame(width: 12, height: 9)
                .rotationEffect(.degrees(-25))
                .offset(x: -2, y: -2)
                .shadow(color: .black.opacity(0.45), radius: 1.2, x: 1, y: 1.5)
        }
        .frame(width: 22, height: 22)
    }
}
