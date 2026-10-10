import AudioToolbox
import AVFoundation
import PlugCore

/// Lists the Audio Unit effects installed on this Mac, Apple's built-ins and
/// third-party plugins alike.
public enum EffectCatalog {
    /// Sorted by manufacturer, then name.
    public static func installedEffects() -> [EffectInfo] {
        var description = AudioComponentDescription()
        description.componentType = kAudioUnitType_Effect
        var seen = Set<EffectID>()
        return AVAudioUnitComponentManager.shared().components(matching: description)
            .map { component in
                let found = component.audioComponentDescription
                return EffectInfo(
                    id: EffectID(type: found.componentType,
                                 subtype: found.componentSubType,
                                 manufacturer: found.componentManufacturer),
                    name: component.name,
                    manufacturer: component.manufacturerName
                )
            }
            .filter { seen.insert($0.id).inserted }
            .sorted { ($0.manufacturer, $0.name) < ($1.manufacturer, $1.name) }
    }
}

extension EffectID {
    var componentDescription: AudioComponentDescription {
        AudioComponentDescription(componentType: type,
                                  componentSubType: subtype,
                                  componentManufacturer: manufacturer,
                                  componentFlags: 0,
                                  componentFlagsMask: 0)
    }
}
