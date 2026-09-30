import Foundation
import AwakeCore

/// `PreferencesStore` that keeps values in memory.
@MainActor
public final class InMemoryPreferencesStore: PreferencesStore {
    private var value: AwakePreferences
    public init(_ value: AwakePreferences = AwakePreferences()) { self.value = value }
    public func load() -> AwakePreferences { value }
    public func save(_ preferences: AwakePreferences) { value = preferences }
}

/// `LoginItemService` that can be told to fail.
@MainActor
public final class InMemoryLoginItemService: LoginItemService {
    public private(set) var isEnabled: Bool
    public var shouldFail = false

    public init(isEnabled: Bool = false) {
        self.isEnabled = isEnabled
    }

    public func setEnabled(_ enabled: Bool) throws {
        if shouldFail { throw NSError(domain: "Awake", code: 2) }
        isEnabled = enabled
    }
}

/// `SystemSleepLockService` with a settable flag and injectable failures.
@MainActor
public final class InMemorySystemSleepLockService: SystemSleepLockService {
    public var disabled: Bool
    public var shouldFailSet = false
    /// Error thrown while `shouldFailSet` is true.
    public var failure: SystemSleepLockError = .commandFailed
    public var isHelperInstalled: Bool
    /// Records the `allowHelperInstall` argument of every write, in order.
    public private(set) var installPermissions: [Bool] = []

    public init(disabled: Bool = false, isHelperInstalled: Bool = true) {
        self.disabled = disabled
        self.isHelperInstalled = isHelperInstalled
    }

    public func isSleepDisabled() async -> Bool { disabled }

    public func setSleepDisabled(_ disabled: Bool, allowHelperInstall: Bool) async throws {
        installPermissions.append(allowHelperInstall)
        if !isHelperInstalled && !allowHelperInstall { throw SystemSleepLockError.helperMissing }
        if shouldFailSet { throw failure }
        self.disabled = disabled
        isHelperInstalled = true
    }
}

/// `SleepControlService` that only remembers the last request.
@MainActor
public final class DemoSleepControlService: SleepControlService {
    private var keepAwake = false
    public init() {}
    public func read() async throws -> Bool { keepAwake }
    public func set(keepAwake: Bool, preventDisplaySleep: Bool) async throws {
        self.keepAwake = keepAwake
    }
}
