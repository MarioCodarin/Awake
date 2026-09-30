import Foundation

/// Holds the in-process protection that complements `pmset disablesleep` (IOKit assertions).
/// System integration belongs behind this protocol, never in the view.
@MainActor
public protocol SleepControlService {
    func read() async throws -> Bool
    func set(keepAwake: Bool, preventDisplaySleep: Bool) async throws
}
