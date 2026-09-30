import Foundation

/// Facts about the running bundle that the UI shows or reacts to.
enum AppInfo {
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }

    /// Launch at login is only reliable once the app lives in /Applications.
    static var isInApplications: Bool {
        Bundle.main.bundleURL.path.hasPrefix("/Applications/")
    }

    static let repositoryURL = URL(string: "https://github.com/MarioCodarin/Awake")!
}
