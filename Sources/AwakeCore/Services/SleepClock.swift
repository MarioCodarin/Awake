import Foundation

/// Abstraction over waiting, so duration timers can be tested without real time.
@MainActor
public protocol SleepClock: AnyObject {
    func sleep(seconds: TimeInterval) async throws
}
