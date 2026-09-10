import Foundation

public enum AwakeDuration: String, CaseIterable, Equatable, Sendable {
    case indefinite
    case minutes15
    case minutes30
    case hours1
    case hours2

    public var seconds: TimeInterval? {
        switch self {
        case .indefinite: return nil
        case .minutes15: return 15 * 60
        case .minutes30: return 30 * 60
        case .hours1: return 60 * 60
        case .hours2: return 2 * 60 * 60
        }
    }

    public var title: String {
        switch self {
        case .indefinite: return "Indefinite"
        case .minutes15: return "15 minutes"
        case .minutes30: return "30 minutes"
        case .hours1: return "1 hour"
        case .hours2: return "2 hours"
        }
    }
}

public struct AwakePreferences: Equatable, Sendable {
    public var keepAwake: Bool
    public var preventDisplaySleep: Bool
    public var duration: AwakeDuration

    public init(
        keepAwake: Bool = false,
        preventDisplaySleep: Bool = true,
        duration: AwakeDuration = .indefinite
    ) {
        self.keepAwake = keepAwake
        self.preventDisplaySleep = preventDisplaySleep
        self.duration = duration
    }
}

@MainActor
public protocol PreferencesStore: AnyObject {
    func load() -> AwakePreferences
    func save(_ preferences: AwakePreferences)
}

@MainActor
public final class InMemoryPreferencesStore: PreferencesStore {
    private var value: AwakePreferences
    public init(_ value: AwakePreferences = AwakePreferences()) { self.value = value }
    public func load() -> AwakePreferences { value }
    public func save(_ preferences: AwakePreferences) { value = preferences }
}

@MainActor
public final class UserDefaultsPreferencesStore: PreferencesStore {
    private let defaults: UserDefaults
    private enum Key {
        static let keepAwake = "keepAwake"
        static let preventDisplaySleep = "preventDisplaySleep"
        static let duration = "duration"
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> AwakePreferences {
        AwakePreferences(
            keepAwake: defaults.bool(forKey: Key.keepAwake),
            preventDisplaySleep: defaults.object(forKey: Key.preventDisplaySleep) as? Bool ?? true,
            duration: AwakeDuration(rawValue: defaults.string(forKey: Key.duration) ?? "") ?? .indefinite
        )
    }

    public func save(_ preferences: AwakePreferences) {
        defaults.set(preferences.keepAwake, forKey: Key.keepAwake)
        defaults.set(preferences.preventDisplaySleep, forKey: Key.preventDisplaySleep)
        defaults.set(preferences.duration.rawValue, forKey: Key.duration)
    }
}

@MainActor
public protocol SleepClock: AnyObject {
    func sleep(seconds: TimeInterval) async throws
}

@MainActor
public final class RealSleepClock: SleepClock {
    public init() {}
    public func sleep(seconds: TimeInterval) async throws {
        let nanos = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanos)
    }
}

@MainActor
public final class ImmediateSleepClock: SleepClock {
    public init() {}
    public func sleep(seconds: TimeInterval) async throws {
        try Task.checkCancellation()
    }
}

@MainActor
public final class ControllableSleepClock: SleepClock {
    public private(set) var sleepCount = 0
    private let box = ContinuationBox()

    public init() {}

    public func sleep(seconds: TimeInterval) async throws {
        sleepCount += 1
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

    public func complete() {
        box.continuation?.resume()
        box.continuation = nil
    }
}

private final class ContinuationBox: @unchecked Sendable {
    var continuation: CheckedContinuation<Void, Error>?
}
