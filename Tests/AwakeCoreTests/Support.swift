import Foundation
import AwakeCore
import AwakePlatform

// Expectation helpers, hand-written fakes and polling utilities shared by every check group.

func expectTrue(_ value: Bool, file: StaticString = #file, line: UInt = #line) {
    precondition(value, "Expected true", file: file, line: line)
}
func expectFalse(_ value: Bool, file: StaticString = #file, line: UInt = #line) {
    precondition(!value, "Expected false", file: file, line: line)
}
func expectNil<T>(_ value: T?, file: StaticString = #file, line: UInt = #line) {
    precondition(value == nil, "Expected nil", file: file, line: line)
}
func expectNotNil<T>(_ value: T?, file: StaticString = #file, line: UInt = #line) {
    precondition(value != nil, "Expected non-nil", file: file, line: line)
}
func expectEqual<T: Equatable>(_ value: T, _ expected: T, file: StaticString = #file, line: UInt = #line) {
    precondition(value == expected, "Expected \(expected), got \(value)", file: file, line: line)
}

/// Polls (yielding) until `condition` holds; fails instead of hanging.
func waitUntil(_ condition: @autoclosure () -> Bool, file: StaticString = #file, line: UInt = #line) async {
    for _ in 0..<20_000 {
        if condition() { return }
        await Task.yield()
    }
    precondition(false, "Timed out waiting for condition", file: file, line: line)
}

/// Lets queued tasks run so "nothing happened" assertions are meaningful.
func settle() async {
    for _ in 0..<100 { await Task.yield() }
}

/// `pmset -g assertions` lines owned by this process only, so a running Awake.app can't interfere.
func ownAssertions() -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
    process.arguments = ["-g", "assertions"]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    do {
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let marker = "pid \(getpid())("
        return String(data: data, encoding: .utf8)?
            .split(separator: "\n")
            .filter { $0.contains(marker) }
            .joined(separator: "\n") ?? ""
    } catch {
        return ""
    }
}

/// Service whose `set` suspends until `resume()` once `suspending` is true.
@MainActor
final class SuspendedService: SleepControlService {
    var suspending = true
    var continuation: CheckedContinuation<Void, Never>?
    private var keepAwake = false
    func read() async throws -> Bool { keepAwake }
    func set(keepAwake: Bool, preventDisplaySleep: Bool) async throws {
        self.keepAwake = keepAwake
        guard suspending else { return }
        await withCheckedContinuation { continuation = $0 }
    }
    func resume() {
        continuation?.resume()
        continuation = nil
    }
}

/// Service that records the last request.
@MainActor
final class RecordingService: SleepControlService {
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

final class FakeAssertionClient: AssertionClient, @unchecked Sendable {
    var createdTypes: [String] = []
    var releaseCount = 0
    var shouldFailCreate = false
    var shouldFailRelease = false
    var failTypes: Set<String> = []
    private var nextID: UInt32 = 1
    func create(type: String, name: String) throws -> UInt32 {
        if shouldFailCreate || failTypes.contains(type) { throw SleepControlError.assertionFailed(1) }
        createdTypes.append(type)
        defer { nextID += 1 }
        return nextID
    }
    func release(id: UInt32) throws {
        if shouldFailRelease { throw SleepControlError.releaseFailed }
        releaseCount += 1
    }
}
