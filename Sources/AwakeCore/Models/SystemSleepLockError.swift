import Foundation

/// Failures when changing the system-wide `pmset disablesleep` flag.
public enum SystemSleepLockError: Error, Equatable {
    /// The privileged helper is not installed and installing it was not allowed.
    case helperMissing
    /// The user dismissed the administrator password prompt.
    case installCancelled
    /// The helper or installer ran but did not succeed.
    case commandFailed
}
