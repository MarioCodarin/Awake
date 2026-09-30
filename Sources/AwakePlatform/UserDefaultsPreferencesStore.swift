import Foundation
import AwakeCore

/// `PreferencesStore` backed by `UserDefaults`.
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
