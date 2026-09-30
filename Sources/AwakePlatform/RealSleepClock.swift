import Foundation
import AwakeCore

/// `SleepClock` that really waits.
@MainActor
public final class RealSleepClock: SleepClock {
    public init() {}

    public func sleep(seconds: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
