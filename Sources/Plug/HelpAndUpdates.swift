import AppKit
import PlugCore

/// Help, About and update checks for Plug's menus.
@MainActor
enum HelpAndUpdates {
    static let downloadPage = URL(string: "https://github.com/erdoar/plug/releases")!
    private static let manualOnline = URL(string: "https://github.com/erdoar/plug/blob/main/MANUAL.md")!
    private static let latestRelease = URL(string: "https://api.github.com/repos/erdoar/plug/releases/latest")!

    /// This build's version from Info.plist; nil when run with `swift run`.
    static var version: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    /// Opens the manual bundled in Plug.app (it works offline), or the copy
    /// on GitHub when Plug runs without its bundle.
    static func openManual() {
        let bundled = Bundle.main.url(forResource: "manual", withExtension: "html", subdirectory: "Manual")
        NSWorkspace.shared.open(bundled ?? manualOnline)
    }

    static func showAbout() {
        let credits = NSAttributedString(
            string: "Audio Unit effects for everything your Mac plays.\nBuilt on Apple's public audio APIs.\n\nHelp > Plug Help opens the manual.",
            attributes: [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.secondaryLabelColor])
        NSApp.activate()
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "Plug",
            .applicationVersion: version ?? "development build",
            .version: "",
            .credits: credits,
        ])
    }

    /// Asks GitHub for the latest published release and says whether it is
    /// newer than this build.
    static func checkForUpdates() {
        Task {
            let result: UpdateCheck
            do {
                result = UpdateCheck.evaluate(currentVersion: version, latest: try await fetchLatestRelease())
            } catch {
                show(title: "Couldn't check for updates",
                     message: "Check your internet connection and try again.\n\n(\(error.localizedDescription))",
                     link: ("Open Download Page", downloadPage))
                return
            }
            switch result {
            case .newer(let available, let pageURL, let current):
                show(title: "Plug \(available) is available",
                     message: "You have Plug \(current). Download the new disk image, quit Plug, and drag the new Plug onto Applications to replace it.",
                     link: ("Open Download Page", URL(string: pageURL) ?? downloadPage))
            case .upToDate(let current):
                show(title: "Plug is up to date", message: "You have Plug \(current), the latest release.", link: nil)
            case .noReleases:
                show(title: "Plug is up to date", message: "No newer version is available.", link: nil)
            case .cannotCompare:
                show(title: "Couldn't compare versions",
                     message: "You can see the latest Plug on the download page.",
                     link: ("Open Download Page", downloadPage))
            }
        }
    }

    /// Nil when GitHub reports no published release (404).
    private static func fetchLatestRelease() async throws -> GitHubRelease? {
        var request = URLRequest(url: latestRelease, timeoutInterval: 15)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Plug/\(version ?? "dev")", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 404 {
            return nil
        }
        guard status == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }

    private static func show(title: String, message: String, link: (label: String, url: URL)?) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        if let link {
            alert.addButton(withTitle: link.label)
            alert.addButton(withTitle: "Close")
        } else {
            alert.addButton(withTitle: "OK")
        }
        NSApp.activate()
        if alert.runModal() == .alertFirstButtonReturn, let link {
            NSWorkspace.shared.open(link.url)
        }
    }
}
