import Foundation
import AwakeCore
import AwakePlatform
import AwakeTestSupport

extension AwakeChecks {
    func testAssertionCreateAndRelease() async throws {
        let client = FakeAssertionClient()
        let service = AssertionSleepControlService(client: client)
        expectFalse(try await service.read())
        try await service.set(keepAwake: true, preventDisplaySleep: true)
        expectEqual(
            client.createdTypes,
            [AssertionType.preventIdleSystemSleep, AssertionType.preventSystemSleep, AssertionType.preventDisplaySleep]
        )
        expectTrue(try await service.read())
        try await service.set(keepAwake: true, preventDisplaySleep: false)
        expectEqual(
            client.createdTypes,
            [
                AssertionType.preventIdleSystemSleep, AssertionType.preventSystemSleep, AssertionType.preventDisplaySleep,
                AssertionType.preventIdleSystemSleep, AssertionType.preventSystemSleep
            ]
        )
        expectEqual(client.releaseCount, 3)
        try await service.set(keepAwake: false, preventDisplaySleep: false)
        expectEqual(client.releaseCount, 5)
        expectFalse(try await service.read())
    }

    func testFallsBackToIdleSystemSleepWhenPreventSystemSleepFails() async throws {
        let client = FakeAssertionClient()
        client.failTypes = [AssertionType.preventSystemSleep]
        let service = AssertionSleepControlService(client: client)
        try await service.set(keepAwake: true, preventDisplaySleep: true)
        expectEqual(client.createdTypes, [AssertionType.preventIdleSystemSleep, AssertionType.preventDisplaySleep])
        expectTrue(try await service.read())
    }

    func testDisplayCreateFailureReleasesPartialAssertions() async throws {
        let client = FakeAssertionClient()
        client.failTypes = [AssertionType.preventDisplaySleep]
        let service = AssertionSleepControlService(client: client)
        do {
            try await service.set(keepAwake: true, preventDisplaySleep: true)
            precondition(false, "Expected display create to fail")
        } catch {
            expectFalse(try await service.read())
            expectEqual(client.releaseCount, 2)
        }
        let model = SleepModel(testing: AssertionSleepControlService(client: client))
        await model.load()
        await model.setKeepAwake(true)
        expectTrue(model.keepAwake)
        expectFalse(model.isBusy)
    }

    func testFailedRollbackKeepsHoldTracked() async throws {
        let client = FakeAssertionClient()
        client.failTypes = [AssertionType.preventDisplaySleep]
        client.shouldFailRelease = true
        let service = AssertionSleepControlService(client: client)
        do {
            try await service.set(keepAwake: true, preventDisplaySleep: true)
            precondition(false, "Expected create/rollback to fail")
        } catch {
            expectTrue(try await service.read())
        }
        client.shouldFailRelease = false
        try await service.set(keepAwake: false, preventDisplaySleep: true)
        expectFalse(try await service.read())
    }

    func testStayingOnThrowsWhenOldReleaseFails() async throws {
        let client = FakeAssertionClient()
        let service = AssertionSleepControlService(client: client)
        try await service.set(keepAwake: true, preventDisplaySleep: true)
        expectTrue(try await service.read())
        client.shouldFailRelease = true
        do {
            try await service.set(keepAwake: true, preventDisplaySleep: false)
            precondition(false, "Expected old release to fail")
        } catch {
            expectTrue(try await service.read())
        }
        client.shouldFailRelease = false
        try await service.set(keepAwake: false, preventDisplaySleep: false)
        expectFalse(try await service.read())
    }

    func testFailedAssertionCreateLeavesKeepAwakeOff() async {
        let client = FakeAssertionClient()
        client.shouldFailCreate = true
        let lock = InMemorySystemSleepLockService()
        let model = SleepModel(testing: AssertionSleepControlService(client: client), systemLock: lock)
        await model.load()
        await model.setKeepAwake(true)
        expectTrue(model.keepAwake)
        expectTrue(lock.disabled)
        expectFalse(model.isBusy)
    }

    func testRealIOKitAssertionCreateAndRelease() async throws {
        let service = AssertionSleepControlService()
        expectFalse(try await service.read())
        try await service.set(keepAwake: true, preventDisplaySleep: true)
        expectTrue(try await service.read())
        let listed = ownAssertions()
        expectTrue(listed.contains("PreventUserIdleSystemSleep named: \"Awake\""))
        expectTrue(listed.contains("PreventUserIdleDisplaySleep named: \"Awake Display\""))
        try await service.set(keepAwake: false, preventDisplaySleep: true)
        expectFalse(try await service.read())
        let after = ownAssertions()
        expectFalse(after.contains("named: \"Awake\""))
        expectFalse(after.contains("named: \"Awake Display\""))
    }
}
