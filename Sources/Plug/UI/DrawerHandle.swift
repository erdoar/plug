import SwiftUI

/// A worn iron drawer pull: two screwed backplates and a bowed handle, dark
/// with patina except the middle, where hands have rubbed it back to brass.
/// Pressing it opens or closes the drawer below the board.
struct DrawerHandle: View {
    let isOpen: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Canvas { context, size in
                let width = size.width
                let height = size.height
                let iron = Color(red: 0.2, green: 0.18, blue: 0.16)
                let brass = Color(red: 0.78, green: 0.6, blue: 0.32)
                var random = SeededRandom(seed: 0xD7A_4E5)

                for x in [width * 0.12, width * 0.88] {
                    let plate = CGRect(x: x - 9, y: 3, width: 18, height: height * 0.62)
                    context.fill(Path(roundedRect: plate, cornerRadius: 4), with: .linearGradient(
                        Gradient(colors: [Color(red: 0.42, green: 0.36, blue: 0.28), iron]),
                        startPoint: CGPoint(x: plate.minX, y: plate.minY),
                        endPoint: CGPoint(x: plate.maxX, y: plate.maxY)))
                    // Scratches in the patina.
                    for _ in 0..<3 {
                        var scratch = Path()
                        let start = CGPoint(x: plate.minX + random.next(in: 2...14), y: plate.minY + random.next(in: 2...10))
                        scratch.move(to: start)
                        scratch.addLine(to: CGPoint(x: start.x + random.next(in: -4...4), y: start.y + random.next(in: 2...6)))
                        context.stroke(scratch, with: .color(.white.opacity(0.18)), lineWidth: 0.6)
                    }
                    let screwCenter = CGPoint(x: x, y: plate.minY + 6)
                    context.fill(Path(ellipseIn: CGRect(x: screwCenter.x - 3, y: screwCenter.y - 3, width: 6, height: 6)),
                                 with: .color(Color(white: 0.5)))
                    var slot = Path()
                    slot.move(to: CGPoint(x: screwCenter.x - 2.5, y: screwCenter.y - 1))
                    slot.addLine(to: CGPoint(x: screwCenter.x + 2.5, y: screwCenter.y + 1))
                    context.stroke(slot, with: .color(.black.opacity(0.6)), lineWidth: 1)
                }

                var bow = Path()
                bow.move(to: CGPoint(x: width * 0.12, y: height * 0.42))
                bow.addCurve(to: CGPoint(x: width * 0.88, y: height * 0.42),
                             control1: CGPoint(x: width * 0.2, y: height * 1.15),
                             control2: CGPoint(x: width * 0.8, y: height * 1.15))
                context.stroke(bow.offsetBy(dx: 0, dy: 2), with: .color(.black.opacity(0.35)),
                               style: StrokeStyle(lineWidth: 7, lineCap: .round))
                context.stroke(bow, with: .linearGradient(
                    Gradient(colors: [iron, brass, iron]),
                    startPoint: CGPoint(x: width * 0.15, y: 0), endPoint: CGPoint(x: width * 0.85, y: 0)),
                               style: StrokeStyle(lineWidth: 6, lineCap: .round))
                context.stroke(bow, with: .linearGradient(
                    Gradient(colors: [.clear, Color(red: 1, green: 0.92, blue: 0.65).opacity(0.65), .clear]),
                    startPoint: CGPoint(x: width * 0.32, y: 0), endPoint: CGPoint(x: width * 0.68, y: 0)),
                               style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
            }
            .frame(width: 130, height: 30)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .help(isOpen ? "Close the drawer" : "Open the drawer")
        .accessibilityLabel(isOpen ? "Close drawer" : "Open drawer")
    }
}
