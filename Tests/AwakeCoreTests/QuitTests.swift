import Foundation
import AwakeCore
import AwakeTestSupport

extension AwakeChecks {
    func testShutdownRestoresSleepWithoutPrompting() async {
        let lock = InMemorySystemSleepLockService(disabled: true)
        let service = RecordingService()
        let model = SleepModel(testing: service, systemLock: lock)
        await model.load()
        expectTrue(model.keepAwake)
        await model.shutdown()
        expectFalse(lock.disabled)
        expectFalse(model.keepAwake)
        expectEqual(service.lastKeepAwake, false)
        expectEqual(lock.installPermissions, [false])
    }

    func testShutdownWithoutHelperLeavesFlagAndDoesNotCrash() async {
        let lock = InMemorySystemSleepLockService(disabled: true, isHelperInstalled: false)
        let model = SleepModel(testing: RecordingService(), systemLock: lock)
        await model.load()
        await model.shutdown()
        expectTrue(lock.disabled)
        expectEqual(lock.installPermissions, [false])
    }

    func testCancelledPasswordPromptIsReportedAndStateKept() async {
        let lock = InMemorySystemSleepLockService(isHelperInstalled: false)
        lock.shouldFailSet = true
        lock.failure = .installCancelled
        let model = SleepModel(testing: RecordingService(), systemLock: lock)
        await model.load()
        await model.setKeepAwake(true)
        expectFalse(model.keepAwake)
        expectTrue(model.errorMessage?.contains("cancelled") == true)
        model.dismissError()
        expectNil(model.errorMessage)
    }

    func testHelperInstalledFlagFollowsSuccessfulInstall() async {
        let lock = InMemorySystemSleepLockService(isHelperInstalled: false)
        let model = SleepModel(testing: RecordingService(), systemLock: lock)
        await model.load()
        expectFalse(model.helperInstalled)
        await model.setKeepAwake(true)
        expectTrue(model.helperInstalled)
    }
}
