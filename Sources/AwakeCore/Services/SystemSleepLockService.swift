import Foundation

/// Reads and writes the system-wide `pmset disablesleep` flag.
@MainActor
public protocol SystemSleepLockService: AnyObject {
    /// Whether the privileged helper needed for password-free changes is present.
    var isHelperInstalled: Bool { get }
    func isSleepDisabled() async -> Bool
    /// Sets the flag. When the helper is missing, installs it (one password prompt) only if
    /// `allowHelperInstall` is true; otherwise throws `SystemSleepLockError.helperMissing`.
    func setSleepDisabled(_ disabled: Bool, allowHelperInstall: Bool) async throws
}
