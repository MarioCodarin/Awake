import Foundation

/// Persists `AwakePreferences`.
@MainActor
public protocol PreferencesStore: AnyObject {
    func load() -> AwakePreferences
    func save(_ preferences: AwakePreferences)
}
