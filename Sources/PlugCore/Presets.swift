import Foundation

/// Named presets, one JSON file each (the same format as the settings file)
/// in a folder. File names come from preset names, so names are cleaned
/// first.
public enum PresetStore {
    /// Trims spaces, turns "/" and ":" into "-", and drops leading dots so a
    /// preset can't become a hidden file or reach outside its folder. Nil if
    /// nothing is left.
    public static func cleanedName(_ name: String) -> String? {
        var cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        while cleaned.hasPrefix(".") {
            cleaned.removeFirst()
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }

    /// Preset names in the folder, sorted alphabetically; empty if the
    /// folder doesn't exist yet.
    public static func names(in directory: URL) -> [String] {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return files
            .filter { $0.pathExtension == "json" }
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    /// Saves or replaces a preset. Returns the cleaned name it was saved as.
    @discardableResult
    public static func save(_ settings: HostSettings, named name: String, in directory: URL) throws -> String {
        guard let cleaned = cleanedName(name) else {
            throw CocoaError(.fileWriteInvalidFileName)
        }
        try SettingsStore.save(settings, to: url(for: cleaned, in: directory))
        return cleaned
    }

    public static func load(named name: String, in directory: URL) -> HostSettings? {
        guard let cleaned = cleanedName(name) else { return nil }
        return SettingsStore.load(from: url(for: cleaned, in: directory))
    }

    public static func delete(named name: String, in directory: URL) throws {
        guard let cleaned = cleanedName(name) else { return }
        try FileManager.default.removeItem(at: url(for: cleaned, in: directory))
    }

    private static func url(for cleanedName: String, in directory: URL) -> URL {
        directory.appendingPathComponent(cleanedName).appendingPathExtension("json")
    }
}
