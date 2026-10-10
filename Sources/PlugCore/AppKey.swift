/// Groups an audio process with the app it belongs to. Many apps play sound
/// from helper processes (browsers in particular), whose bundle IDs extend
/// the app's own, e.g. "com.google.Chrome.helper.Renderer" belongs to
/// "com.google.Chrome". Capturing an app captures all of its helpers.
public enum AppKey {
    public static func forBundleID(_ bundleID: String) -> String {
        let parts = bundleID.split(separator: ".", omittingEmptySubsequences: false)
        guard let helper = parts.firstIndex(where: { $0.lowercased().hasPrefix("helper") }),
              helper >= 2 else { return bundleID }
        return parts[..<helper].joined(separator: ".")
    }
}
