import SwiftUI

/// A rough-sawn pine board, drawn procedurally: pale pine base, wavy grain
/// with darker latewood bands, a couple of knots, and the faint arcs a
/// circular saw leaves. A fixed seed keeps the same board every launch.
struct PineBoard: View {
    var body: some View {
        Canvas { context, size in
            var random = SeededRandom(seed: 0x51_EE_D0_0D)
            let rect = CGRect(origin: .zero, size: size)
            let latewood = Color(red: 0.60, green: 0.40, blue: 0.20)

            context.fill(Path(rect), with: .linearGradient(
                Gradient(colors: [Color(red: 0.91, green: 0.78, blue: 0.55),
                                  Color(red: 0.85, green: 0.69, blue: 0.46)]),
                startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))

            // Grain runs along the board.
            var y: CGFloat = 0
            while y < size.height {
                let isLatewood = random.next() < 0.22
                let amplitude = random.next(in: 0.6...2.6)
                let wavelength = random.next(in: 140...360)
                let phase = random.next(in: 0...(2 * .pi))
                var grain = Path()
                grain.move(to: CGPoint(x: 0, y: y))
                for x in stride(from: CGFloat(0), through: size.width, by: 6) {
                    grain.addLine(to: CGPoint(x: x, y: y + amplitude * sin(x / wavelength * 2 * .pi + phase)))
                }
                context.stroke(grain,
                               with: .color(latewood.opacity(isLatewood ? 0.33 : 0.11)),
                               lineWidth: isLatewood ? random.next(in: 1.0...2.2) : 0.6)
                y += random.next(in: 2.2...4.2)
            }

            // Knots: concentric rings around a dark heart.
            for _ in 0..<2 {
                let center = CGPoint(x: random.next(in: 0.2...0.8) * size.width,
                                     y: random.next(in: 0.25...0.75) * size.height)
                let width = random.next(in: 14...22)
                for ring in stride(from: 1.0, to: 0.15, by: -0.17) {
                    let ellipse = CGRect(x: center.x - width * ring, y: center.y - width * 0.45 * ring,
                                         width: 2 * width * ring, height: width * 0.9 * ring)
                    context.stroke(Path(ellipseIn: ellipse), with: .color(latewood.opacity(0.28)), lineWidth: 1)
                }
                let heart = CGRect(x: center.x - width * 0.22, y: center.y - width * 0.12,
                                   width: width * 0.44, height: width * 0.24)
                context.fill(Path(ellipseIn: heart), with: .color(Color(red: 0.35, green: 0.2, blue: 0.08).opacity(0.6)))
            }

            // Circular saw marks across the grain.
            let radius = max(size.height * 2.5, 300)
            var x = random.next(in: 0...10)
            while x < size.width + radius * 0.1 {
                var arc = Path()
                arc.addArc(center: CGPoint(x: x - radius, y: size.height / 2), radius: radius,
                           startAngle: .degrees(-25), endAngle: .degrees(25), clockwise: false)
                context.stroke(arc, with: .color(.black.opacity(0.055)), lineWidth: 1.3)
                x += random.next(in: 9...16)
            }

            // Worn edge.
            context.stroke(Path(rect.insetBy(dx: 1, dy: 1)), with: .color(.black.opacity(0.28)), lineWidth: 2)
        }
    }
}

/// Small deterministic generator so the board looks the same every time.
struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> Double {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Double(state >> 11) / Double(UInt64(1) << 53)
    }

    mutating func next(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + (range.upperBound - range.lowerBound) * next()
    }
}

/// Text that looks burnt into the wood.
struct EngravedLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .heavy, design: .serif))
            .tracking(2)
            .foregroundStyle(Color(red: 0.33, green: 0.18, blue: 0.07).opacity(0.9))
            .shadow(color: .white.opacity(0.45), radius: 0, x: 0, y: 1)
    }
}
