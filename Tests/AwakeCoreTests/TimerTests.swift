import Foundation
import AwakeCore
import AwakeTestSupport

extension AwakeChecks {
    func testLoadDoesNotRestartRunningTimer() async {
        let clock = ControllableSleepClock()
        let lock = InMemorySystemSleepLockService(disabled: true)
        let store = InMemoryPreferencesStore(AwakePreferences(duration: .minutes15))
        let model = SleepModel(testing: RecordingService(), store: store, clock: clock, systemLock: lock)
        await model.load()
        await waitUntil(clock.sleepCount == 1)
        let firstEnd = model.endDate
        expectNotNil(firstEnd)
        expectEqual(clock.lastSeconds, 15 * 60)
        await model.load()
        await model.load()
        await settle()
        expectEqual(clock.sleepCount, 1)
        expectEqual(model.endDate, firstEnd)
    }

    func testEndDateTracksTimerLifecycle() async {
        let clock = ControllableSleepClock()
        let model = SleepModel(testing: RecordingService(), clock: clock)
        await model.load()
        await model.setDuration(.hours1)
        expectNil(model.endDate)
        await model.setKeepAwake(true)
        expectNotNil(model.endDate)
        await model.setDuration(.indefinite)
        expectNil(model.endDate)
        await model.setDuration(.minutes30)
        expectNotNil(model.endDate)
        await model.setKeepAwake(false)
        expectNil(model.endDate)
    }

    func testExpiryDuringBusyWriteIsAppliedAfterwards() async {
        let service = SuspendedService()
        service.suspending = false
        let clock = ControllableSleepClock()
        let lock = InMemorySystemSleepLockService()
        let model = SleepModel(testing: service, clock: clock, systemLock: lock)
        await model.load()
        await model.setDuration(.minutes15)
        await model.setKeepAwake(true)
        await waitUntil(clock.sleepCount == 1)
        service.suspending = true
        let write = Task { await model.setPreventDisplaySleep(false) }
        await waitUntil(service.continuation != nil)
        expectTrue(model.isBusy)
        clock.complete()
        await settle()
        expectTrue(model.keepAwake)
        service.resume()
        await write.value
        await waitUntil(!model.keepAwake)
        expectFalse(lock.disabled)
    }

    func testTimerExpiryNeverPromptsForPassword() async {
        let clock = ControllableSleepClock()
        let lock = InMemorySystemSleepLockService()
        let model = SleepModel(testing: RecordingService(), clock: clock, systemLock: lock)
        await model.load()
        await model.setDuration(.minutes15)
        await model.setKeepAwake(true)
        await waitUntil(clock.sleepCount == 1)
        clock.complete()
        await waitUntil(!model.keepAwake)
        expectEqual(lock.installPermissions, [true, false])
    }
}
