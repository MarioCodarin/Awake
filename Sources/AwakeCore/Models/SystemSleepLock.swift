import Foundation

/// Pure helpers for the `pmset disablesleep` integration. No processes are started here.
public enum SystemSleepLock {
    /// Root-owned script that may only run `pmset -a disablesleep 0|1`.
    public static let helperPath = "/Library/PrivilegedHelperTools/com.mariocodarin.Awake.pmset"

    /// Parses `pmset -g` output and reports whether `SleepDisabled` is 1.
    public static func isDisabled(in pmsetOutput: String) -> Bool {
        for raw in pmsetOutput.split(whereSeparator: \.isNewline) {
            let compact = raw.split(whereSeparator: \.isWhitespace).joined().lowercased()
            if compact.hasPrefix("sleepdisabled") {
                return compact.hasSuffix("1")
            }
        }
        return false
    }

    /// The sudoers rule that lets `user` run the helper with exactly `0` or `1`, without a password.
    public static func sudoersLine(user: String) -> String {
        "\(user) ALL=(root) NOPASSWD: \(helperPath) 0, \(helperPath) 1"
    }

    public static func isHelperInstalled(
        fileExists: (String) -> Bool = { FileManager.default.isExecutableFile(atPath: $0) }
    ) -> Bool {
        fileExists(helperPath)
    }
}
