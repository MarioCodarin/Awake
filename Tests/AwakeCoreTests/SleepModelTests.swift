import Foundation
import AwakeCore

@main
@MainActor
struct SleepModelTests {
    static func main() async throws {
        let tests = Self()
        await tests.testDemoStartsOffAndRetainsStateAcrossLoads()
        await tests.testFailedUpdatePreservesLastConfirmedStateAndCanRetry()
        await tests.testPendingUpdateDisablesFurtherWrites()
        try await tests.testAssertionCreateAndRelease()
        try await tests.testFallsBackToIdleSystemSleepWhenPreventSystemSleepFails()
        try await tests.testDisplayCreateFailureReleasesPartialAssertions()
        await tests.testFailedAssertionCreateLeavesKeepAwakeOff()
        await tests.testTimerExpiryTurnsKeepAwakeOff()
        await tests.testChangingDurationWhileOnCancelsPreviousTimer()
        await tests.testLoadRestoresKeepAwakeAndDisplayPreference()
        await tests.testLoginItemFailureDoesNotClaimEnabled()
        await tests.testPreferencesRoundTripThroughUserDefaults()
        try await tests.testRealIOKitAssertionCreateAndRelease()
        print("PASS: all 13 state-management scenarios")
    }

    func testDemoStartsOffAndRetainsStateAcrossLoads() async {
        let service = DemoSleepControlService()
        let model = SleepModel(service: service)
        await model.load()
        expectFalse(model.keepAwake)
        await model.setKeepAwake(true)
        await model.load()
        expectTrue(model.keepAwake)
        let reopened = SleepModel(service: service)
        await reopened.load()
        expectTrue(reopened.keepAwake)
        await reopened.setKeepAwake(false)
        expectFalse(reopened.keepAwake)
        expectNil(reopened.errorMessage)
    }

    func testFailedUpdatePreservesLastConfirmedStateAndCanRetry() async {
        let service = FailingService()
        let model = SleepModel(service: service)
        await model.load()
        expectTrue(model.keepAwake)
        await model.setKeepAwake(false)
        expectTrue(model.keepAwake)
        expectNotNil(model.errorMessage)
        expectFalse(model.isBusy)
        service.shouldFail = false
        await model.setKeepAwake(false)
        expectFalse(model.keepAwake)
        expectNil(model.errorMessage)
    }

    func testPendingUpdateDisablesFurtherWrites() async {
        let service = SuspendedService()
        let model = SleepModel(service: service)
        let update = Task { await model.setKeepAwake(true) }
        while service.continuation == nil { await Task.yield() }
        expectTrue(model.isBusy)
        expectFalse(model.keepAwake)
        await model.setKeepAwake(false)
        service.continuation?.resume()
        await update.value
        expectTrue(model.keepAwake)
        expectFalse(model.isBusy)
    }

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
        let model = SleepModel(service: AssertionSleepControlService(client: client))
        await model.load()
        await model.setKeepAwake(true)
        expectFalse(model.keepAwake)
        expectNotNil(model.errorMessage)
    }

    func testFailedAssertionCreateLeavesKeepAwakeOff() async {
        let client = FakeAssertionClient()
        client.shouldFailCreate = true
        let model = SleepModel(service: AssertionSleepControlService(client: client))
        await model.load()
        await model.setKeepAwake(true)
        expectFalse(model.keepAwake)
        expectNotNil(model.errorMessage)
        expectFalse(model.isBusy)
    }

    func testTimerExpiryTurnsKeepAwakeOff() async {
        let service = RecordingService()
        let clock = ControllableSleepClock()
        let model = SleepModel(service: service, clock: clock)
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
        let model = SleepModel(service: service, clock: clock)
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
        let model = SleepModel(service: service, store: store, clock: clock)
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
        let model = SleepModel(service: DemoSleepControlService(), loginItem: login)
        await model.load()
        expectFalse(model.launchAtLogin)
        model.setLaunchAtLogin(true)
        expectFalse(model.launchAtLogin)
        expectNotNil(model.errorMessage)
    }

    func testRealIOKitAssertionCreateAndRelease() async throws {
        let service = AssertionSleepControlService()
        expectFalse(try await service.read())
        try await service.set(keepAwake: true, preventDisplaySleep: true)
        expectTrue(try await service.read())
        let listed = pmsetAssertions()
        expectTrue(listed.contains("PreventUserIdleSystemSleep named: \"Awake\""))
        expectTrue(listed.contains("PreventSystemSleep named: \"Awake\""))
        expectTrue(listed.contains("PreventUserIdleDisplaySleep named: \"Awake Display\""))
        try await service.set(keepAwake: false, preventDisplaySleep: true)
        expectFalse(try await service.read())
        let after = pmsetAssertions()
        expectFalse(after.contains("named: \"Awake\""))
        expectFalse(after.contains("named: \"Awake Display\""))
    }

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

@MainActor
private final class FailingService: SleepControlService {
    var shouldFail = true
    func read() async throws -> Bool { true }
    func set(keepAwake: Bool, preventDisplaySleep: Bool) async throws {
        if shouldFail { throw NSError(domain: "Test", code: 1) }
    }
}

@MainActor
private final class SuspendedService: SleepControlService {
    var continuation: CheckedContinuation<Void, Never>?
    func read() async throws -> Bool { false }
    func set(keepAwake: Bool, preventDisplaySleep: Bool) async throws {
        await withCheckedContinuation { continuation = $0 }
    }
}

@MainActor
private final class RecordingService: SleepControlService {
    var lastKeepAwake: Bool?
    var lastPreventDisplaySleep: Bool?
    private var keepAwake = false
    func read() async throws -> Bool { keepAwake }
    func set(keepAwake: Bool, preventDisplaySleep: Bool) async throws {
        self.keepAwake = keepAwake
        lastKeepAwake = keepAwake
        lastPreventDisplaySleep = preventDisplaySleep
    }
}

private final class FakeAssertionClient: AssertionClient, @unchecked Sendable {
    var createdTypes: [String] = []
    var releaseCount = 0
    var shouldFailCreate = false
    var failTypes: Set<String> = []
    private var nextID: UInt32 = 1
    func create(type: String, name: String) throws -> UInt32 {
        if shouldFailCreate || failTypes.contains(type) { throw SleepControlError.assertionFailed(1) }
        createdTypes.append(type)
        defer { nextID += 1 }
        return nextID
    }
    func release(id: UInt32) throws {
        releaseCount += 1
    }
}

private func pmsetAssertions() -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
    process.arguments = ["-g", "assertions"]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    do {
        try process.run()
        process.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    } catch {
        return ""
    }
}

private func expectTrue(_ value: Bool, file: StaticString = #file, line: UInt = #line) {
    precondition(value, "Expected true", file: file, line: line)
}
private func expectFalse(_ value: Bool, file: StaticString = #file, line: UInt = #line) {
    precondition(!value, "Expected false", file: file, line: line)
}
private func expectNil<T>(_ value: T?, file: StaticString = #file, line: UInt = #line) {
    precondition(value == nil, "Expected nil", file: file, line: line)
}
private func expectNotNil<T>(_ value: T?, file: StaticString = #file, line: UInt = #line) {
    precondition(value != nil, "Expected non-nil", file: file, line: line)
}
private func expectEqual<T: Equatable>(_ value: T, _ expected: T, file: StaticString = #file, line: UInt = #line) {
    precondition(value == expected, "Expected \(expected), got \(value)", file: file, line: line)
}

private func waitUntil(_ condition: @autoclosure () -> Bool, file: StaticString = #file, line: UInt = #line) async {
    for _ in 0..<20_000 {
        if condition() { return }
        await Task.yield()
    }
    precondition(false, "Timed out waiting for condition", file: file, line: line)
}
