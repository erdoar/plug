import Foundation

/// The master knob's taper. The knob's position (0...1) maps to a gain with
/// a cubic curve, which feels like an ordinary volume control: half way is
/// about -18 dB, and the top is unity (0 dB), so the knob never boosts.
public enum MasterVolume {
    public static func gain(forPosition position: Double) -> Float {
        let clamped = min(max(position, 0), 1)
        return Float(clamped * clamped * clamped)
    }

    /// The level in decibels, nil for silence.
    public static func decibels(forPosition position: Double) -> Double? {
        let gain = Double(gain(forPosition: position))
        return gain > 0 ? 20 * log10(gain) : nil
    }

    /// "0.0 dB", "-18.1 dB", or "-∞ dB" for silence.
    public static func label(forPosition position: Double) -> String {
        guard let decibels = decibels(forPosition: position) else { return "-∞ dB" }
        return String(format: "%.1f dB", abs(decibels) < 0.05 ? 0 : decibels)
    }
}
