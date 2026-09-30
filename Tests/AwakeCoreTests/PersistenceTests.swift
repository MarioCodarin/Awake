import Foundation
import AwakeCore
import AwakePlatform

extension AwakeChecks {
    func testPreferencesRoundTripThroughUserDefaults() async {
        let suite = "test.awake." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let store = UserDefaultsPreferencesStore(defaults: defaults)
        let prefs = AwakePreferences(keepAwake: true, preventDisplaySleep: false, duration: .hours1)
        store.save(prefs)
        let loaded = store.load()
        expectEqual(loaded.keepAwake, true)
        expectEqual(loaded.preventDisplaySleep, false)
        expectEqual(loaded.duration, .hours1)
        defaults.removePersistentDomain(forName: suite)
    }
}
