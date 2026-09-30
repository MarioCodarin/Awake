import Foundation
import AwakeCore

/// Clock whose waits finish immediately (or throw if the task was cancelled).
@MainActor
public final class ImmediateSleepClock: SleepClock {
    public init() {}
    public func sleep(seconds: TimeInterval) async throws {
        try Task.checkCancellation()
    }
}

/// Clock whose waits stay suspended until `complete()` is called. Timer tests must use this
/// instead of sleeping real minutes.
@MainActor
public final class ControllableSleepClock: SleepClock {
    /// Number of waits started so far.
    public private(set) var sleepCount = 0
    /// Seconds requested by the most recent wait.
    public private(set) var lastSeconds: TimeInterval?
    private let box = ContinuationBox()

    public init() {}

    public func sleep(seconds: TimeInterval) async throws {
        sleepCount += 1
        lastSeconds = seconds
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                if Task.isCancelled {
                    cont.resume(throwing: CancellationError())
                } else {
                    self.box.continuation = cont
                }
            }
        } onCancel: {
            let cont = self.box.continuation
            self.box.continuation = nil
            cont?.resume(throwing: CancellationError())
        }
    }

    /// Finishes the current wait.
    public func complete() {
        box.continuation?.resume()
        box.continuation = nil
    }
}

private final class ContinuationBox: @unchecked Sendable {
    var continuation: CheckedContinuation<Void, Error>?
}
