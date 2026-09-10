import Foundation

/// System integration belongs here, never in the view.
@MainActor
public protocol SleepControlService {
    func read() async throws -> Bool
    func set(keepAwake: Bool, preventDisplaySleep: Bool) async throws
}

@MainActor
public final class DemoSleepControlService: SleepControlService {
    private var keepAwake = false
    public init() {}
    public func read() async throws -> Bool { keepAwake }
    public func set(keepAwake: Bool, preventDisplaySleep: Bool) async throws {
        self.keepAwake = keepAwake
        _ = preventDisplaySleep
    }
}
