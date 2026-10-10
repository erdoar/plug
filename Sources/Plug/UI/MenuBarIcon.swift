import AppKit

/// A bold VU meter for the menu bar: a thick scale arc with three ticks, a
/// needle swung towards the top end, and a pivot. A template image, so macOS
/// draws it in the menu bar's own colour (dark or light).
enum MenuBarIcon {
    static let image: NSImage = {
        let image = NSImage(size: NSSize(width: 20, height: 18), flipped: false) { _ in
            let pivot = NSPoint(x: 10, y: 4)
            let radius: CGFloat = 8

            func point(_ degrees: CGFloat, _ distance: CGFloat) -> NSPoint {
                let radians = degrees * .pi / 180
                return NSPoint(x: pivot.x + distance * cos(radians), y: pivot.y + distance * sin(radians))
            }

            NSColor.black.set()
            let scale = NSBezierPath()
            scale.appendArc(withCenter: pivot, radius: radius, startAngle: 152, endAngle: 28, clockwise: true)
            scale.lineWidth = 2.6
            scale.lineCapStyle = .round
            scale.stroke()

            for degrees: CGFloat in [128, 90, 52] {
                let tick = NSBezierPath()
                tick.move(to: point(degrees, radius + 2))
                tick.line(to: point(degrees, radius + 4))
                tick.lineWidth = 1.8
                tick.lineCapStyle = .round
                tick.stroke()
            }

            let needle = NSBezierPath()
            needle.move(to: pivot)
            needle.line(to: point(60, radius + 1))
            needle.lineWidth = 2.4
            needle.lineCapStyle = .round
            needle.stroke()

            NSBezierPath(ovalIn: NSRect(x: pivot.x - 2.4, y: pivot.y - 2.4, width: 4.8, height: 4.8)).fill()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Plug master volume"
        return image
    }()
}
