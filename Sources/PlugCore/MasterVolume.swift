import Foundation

/// The master knob's taper, like a mixing-desk fader: unity (0 dB) sits at
/// `unityPosition` of the travel, below it a cubic curve falls to silence,
/// and above it the level rises evenly to `maximumBoost` dB.
public enum MasterVolume {
    /// Where 0 dB sits on the knob (marked by the tack).
    public static let unityPosition = 0.8
    /// The most the knob can boost, in dB.
    public static let maximumBoost = 10.0
    /// The gain at the top of the knob (+10 dB ≈ 3.16).
    public static let maximumGain = Float(pow(10, maximumBoost / 20))

    public static func gain(forPosition position: Double) -> Float {
        let clamped = min(max(position, 0), 1)
        if clamped >= unityPosition {
            let decibels = maximumBoost * (clamped - unityPosition) / (1 - unityPosition)
            return Float(pow(10, decibels / 20))
        }
        let below = clamped / unityPosition
        return Float(below * below * below)
    }

    /// The level in decibels, nil for silence.
    public static func decibels(forPosition position: Double) -> Double? {
        let gain = Double(gain(forPosition: position))
        return gain > 0 ? 20 * log10(gain) : nil
    }

    /// "+10.0 dB", "0.0 dB", "-18.1 dB", or "-∞ dB" for silence.
    public static func label(forPosition position: Double) -> String {
        guard let decibels = decibels(forPosition: position) else { return "-∞ dB" }
        if abs(decibels) < 0.05 { return "0.0 dB" }
        return String(format: "%+.1f dB", decibels)
    }
}
