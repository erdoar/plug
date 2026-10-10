import Foundation

/// A version like "1.2.3" (a leading "v" is allowed, as in release tags).
/// Missing parts count as zero, so "1.2" equals "1.2.0".
public struct AppVersion: Comparable, CustomStringConvertible {
    public let parts: [Int]

    public init?(_ text: String) {
        var trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.first == "v" || trimmed.first == "V" {
            trimmed.removeFirst()
        }
        let pieces = trimmed.split(separator: ".", omittingEmptySubsequences: false)
        guard (1...4).contains(pieces.count) else { return nil }
        var parts: [Int] = []
        for piece in pieces {
            guard let number = Int(piece), number >= 0 else { return nil }
            parts.append(number)
        }
        self.parts = parts
    }

    public var description: String { parts.map(String.init).joined(separator: ".") }

    private func padded(to count: Int) -> [Int] {
        parts + Array(repeating: 0, count: max(0, count - parts.count))
    }

    public static func == (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let count = max(lhs.parts.count, rhs.parts.count)
        return lhs.padded(to: count) == rhs.padded(to: count)
    }

    public static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let count = max(lhs.parts.count, rhs.parts.count)
        return lhs.padded(to: count).lexicographicallyPrecedes(rhs.padded(to: count))
    }
}

/// The parts of GitHub's "latest release" reply that Plug uses.
public struct GitHubRelease: Decodable, Equatable {
    public let tagName: String
    public let pageURL: String

    public init(tagName: String, pageURL: String) {
        self.tagName = tagName
        self.pageURL = pageURL
    }

    private enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case pageURL = "html_url"
    }
}

/// What "Check for Updates" tells the user.
public enum UpdateCheck: Equatable {
    case upToDate(AppVersion)
    case newer(AppVersion, pageURL: String, current: AppVersion)
    /// GitHub has no published release yet.
    case noReleases
    /// This build has no usable version (e.g. run with `swift run`), or the
    /// release's tag isn't a version.
    case cannotCompare

    /// `latest` is nil when GitHub reports no published release.
    public static func evaluate(currentVersion: String?, latest: GitHubRelease?) -> UpdateCheck {
        guard let latest else { return .noReleases }
        guard let current = currentVersion.flatMap(AppVersion.init),
              let available = AppVersion(latest.tagName) else { return .cannotCompare }
        return available > current ? .newer(available, pageURL: latest.pageURL, current: current) : .upToDate(current)
    }
}
