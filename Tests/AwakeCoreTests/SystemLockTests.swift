import Foundation
import AwakeCore
import AwakeTestSupport

extension AwakeChecks {
    func testParsesPmsetSleepDisabled() {
        expectTrue(SystemSleepLock.isDisabled(in: "System-wide power settings:\n SleepDisabled         1\n"))
        expectFalse(SystemSleepLock.isDisabled(in: "System-wide power settings:\n SleepDisabled         0\n"))
        expectTrue(SystemSleepLock.isDisabled(in: "SleepDisabled1"))
        expectFalse(SystemSleepLock.isDisabled(in: "sleep 1 (sleep prevented by powerd)\n"))
    }

    func testSudoersLineAllowsOnlyPmsetZeroOrOne() {
        let line = SystemSleepLock.sudoersLine(user: "mariocodarin")
        expectTrue(line.contains("NOPASSWD:"))
        expectTrue(line.contains(SystemSleepLock.helperPath + " 0"))
        expectTrue(line.contains(SystemSleepLock.helperPath + " 1"))
        expectFalse(line.contains("/usr/bin/pmset"))
    }

    func testHelperInstalledUsesPrivilegedPath() {
        expectTrue(SystemSleepLock.helperPath.hasPrefix("/Library/PrivilegedHelperTools/"))
        expectFalse(SystemSleepLock.isHelperInstalled(fileExists: { _ in false }))
        expectTrue(SystemSleepLock.isHelperInstalled(fileExists: { $0 == SystemSleepLock.helperPath }))
    }

    func testLoadSurfacesLeftoverPmsetLock() async {
        let lock = InMemorySystemSleepLockService(disabled: true)
        let model = SleepModel(testing: DemoSleepControlService(), systemLock: lock)
        await model.load()
        expectTrue(model.keepAwake)
    }

    func testUnlockClearsLeftoverPmsetLock() async {
        let lock = InMemorySystemSleepLockService(disabled: true)
        let model = SleepModel(testing: DemoSleepControlService(), systemLock: lock)
        await model.load()
        expectTrue(model.keepAwake)
        await model.setKeepAwake(false)
        expectFalse(model.keepAwake)
        expectFalse(lock.disabled)
        expectNil(model.errorMessage)
    }

    func testToggleWritesPmsetFlag() async {
        let lock = InMemorySystemSleepLockService()
        let model = SleepModel(testing: DemoSleepControlService(), systemLock: lock)
        await model.load()
        expectFalse(lock.disabled)
        await model.setKeepAwake(true)
        expectTrue(lock.disabled)
        expectTrue(model.keepAwake)
        await model.setKeepAwake(false)
        expectFalse(lock.disabled)
        expectFalse(model.keepAwake)
    }
}
