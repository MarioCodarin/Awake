import Foundation
import AwakeCore
import AwakeTestSupport

extension AwakeChecks {
    func testDemoStartsOffAndRetainsStateAcrossLoads() async {
        let service = DemoSleepControlService()
        let lock = InMemorySystemSleepLockService()
        let model = SleepModel(testing: service, systemLock: lock)
        await model.load()
        expectFalse(model.keepAwake)
        await model.setKeepAwake(true)
        await model.load()
        expectTrue(model.keepAwake)
        let reopened = SleepModel(testing: service, systemLock: lock)
        await reopened.load()
        expectTrue(reopened.keepAwake)
        await reopened.setKeepAwake(false)
        expectFalse(reopened.keepAwake)
        expectNil(reopened.errorMessage)
    }

    func testFailedUpdatePreservesLastConfirmedStateAndCanRetry() async {
        let lock = InMemorySystemSleepLockService(disabled: true)
        lock.shouldFailSet = true
        let model = SleepModel(testing: DemoSleepControlService(), systemLock: lock)
        await model.load()
        expectTrue(model.keepAwake)
        await model.setKeepAwake(false)
        expectTrue(model.keepAwake)
        expectTrue(lock.disabled)
        expectNotNil(model.errorMessage)
        expectFalse(model.isBusy)
        lock.shouldFailSet = false
        await model.setKeepAwake(false)
        expectFalse(model.keepAwake)
        expectFalse(lock.disabled)
        expectNil(model.errorMessage)
    }

    func testPendingUpdateDisablesFurtherWrites() async {
        let service = SuspendedService()
        let model = SleepModel(testing: service)
        let update = Task { await model.setKeepAwake(true) }
        while service.continuation == nil { await Task.yield() }
        expectTrue(model.isBusy)
        expectTrue(model.keepAwake)
        await model.setKeepAwake(false)
        service.continuation?.resume()
        await update.value
        expectTrue(model.keepAwake)
        expectFalse(model.isBusy)
    }

    func testTimerExpiryTurnsKeepAwakeOff() async {
        let service = RecordingService()
        let clock = ControllableSleepClock()
        let model = SleepModel(testing: service, clock: clock)
        await model.load()
        await model.setDuration(.minutes15)
        await model.setKeepAwake(true)
        expectTrue(model.keepAwake)
        await waitUntil(clock.sleepCount == 1)
        clock.complete()
        await waitUntil(!model.keepAwake)
        expectFalse(model.keepAwake)
        expectEqual(service.lastKeepAwake, false)
    }

    func testChangingDurationWhileOnCancelsPreviousTimer() async {
        let service = RecordingService()
        let clock = ControllableSleepClock()
        let model = SleepModel(testing: service, clock: clock)
        await model.load()
        await model.setDuration(.minutes15)
        await model.setKeepAwake(true)
        await waitUntil(clock.sleepCount == 1)
        expectEqual(clock.sleepCount, 1)
        await model.setDuration(.minutes30)
        await waitUntil(clock.sleepCount == 2)
        expectEqual(clock.sleepCount, 2)
        expectTrue(model.keepAwake)
        clock.complete()
        await waitUntil(!model.keepAwake)
        expectFalse(model.keepAwake)
    }

    func testLoadRestoresKeepAwakeAndDisplayPreference() async {
        let service = RecordingService()
        let store = InMemoryPreferencesStore(
            AwakePreferences(keepAwake: true, preventDisplaySleep: false, duration: .minutes15)
        )
        let clock = ControllableSleepClock()
        let lock = InMemorySystemSleepLockService(disabled: true)
        let model = SleepModel(testing: service, store: store, clock: clock, systemLock: lock)
        await model.load()
        expectTrue(model.keepAwake)
        expectFalse(model.preventDisplaySleep)
        expectEqual(model.duration, .minutes15)
        expectEqual(service.lastKeepAwake, true)
        expectEqual(service.lastPreventDisplaySleep, false)
        await model.setKeepAwake(false)
        expectFalse(model.keepAwake)
    }

    func testLoginItemFailureDoesNotClaimEnabled() async {
        let login = InMemoryLoginItemService()
        login.shouldFail = true
        let model = SleepModel(testing: DemoSleepControlService(), loginItem: login)
        await model.load()
        expectFalse(model.launchAtLogin)
        model.setLaunchAtLogin(true)
        expectFalse(model.launchAtLogin)
        expectNotNil(model.errorMessage)
    }
}
