import Foundation
import AwakeCore

extension SleepModel {
    /// Builds a model with in-memory defaults for any dependency not supplied. The default clock
    /// never fires; pass a `ControllableSleepClock` to drive timers.
    @MainActor
    public convenience init(
        testing service: any SleepControlService,
        store: (any PreferencesStore)? = nil,
        clock: (any SleepClock)? = nil,
        loginItem: (any LoginItemService)? = nil,
        systemLock: (any SystemSleepLockService)? = nil
    ) {
        self.init(
            service: service,
            store: store ?? InMemoryPreferencesStore(),
            clock: clock ?? ControllableSleepClock(),
            loginItem: loginItem ?? InMemoryLoginItemService(),
            systemLock: systemLock ?? InMemorySystemSleepLockService()
        )
    }
}
