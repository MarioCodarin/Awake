import Foundation
import IOKit.pwr_mgt

public enum AssertionType {
    public static let preventDisplaySleep = kIOPMAssertionTypePreventUserIdleDisplaySleep as String
    public static let preventIdleSystemSleep = kIOPMAssertionTypePreventUserIdleSystemSleep as String
    /// Stronger AC-only assertion (`caffeinate -s`). Create often succeeds on battery without being honored.
    public static let preventSystemSleep = kIOPMAssertionTypePreventSystemSleep as String
}

public enum SleepControlError: Error, Equatable {
    case assertionFailed(Int32)
    case releaseFailed
}

public protocol AssertionClient: AnyObject {
    func create(type: String, name: String) throws -> UInt32
    func release(id: UInt32) throws
}

public final class IOKitAssertionClient: AssertionClient {
    public init() {}

    public func create(type: String, name: String) throws -> UInt32 {
        var assertionID: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(
            type as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            name as CFString,
            &assertionID
        )
        guard result == kIOReturnSuccess else {
            throw SleepControlError.assertionFailed(result)
        }
        return assertionID
    }

    public func release(id: UInt32) throws {
        let result = IOPMAssertionRelease(IOPMAssertionID(id))
        guard result == kIOReturnSuccess else {
            throw SleepControlError.assertionFailed(result)
        }
    }
}

@MainActor
public final class AssertionSleepControlService: SleepControlService {
    private let client: any AssertionClient
    private var assertionIDs: [UInt32] = []

    public init(client: any AssertionClient = IOKitAssertionClient()) {
        self.client = client
    }

    public func read() async throws -> Bool {
        !assertionIDs.isEmpty
    }

    public func set(keepAwake: Bool, preventDisplaySleep: Bool) async throws {
        let newIDs: [UInt32]
        do {
            newIDs = keepAwake ? try makeAssertions(preventDisplaySleep: preventDisplaySleep) : []
        } catch let partial as UnreleasedHold {
            assertionIDs.append(contentsOf: partial.ids)
            throw SleepControlError.releaseFailed
        }
        let oldIDs = assertionIDs
        assertionIDs = newIDs
        let leftover = releaseBestEffort(oldIDs)
        assertionIDs.append(contentsOf: leftover)
        if !leftover.isEmpty {
            throw SleepControlError.releaseFailed
        }
    }

    deinit {
        for id in assertionIDs {
            try? client.release(id: id)
        }
    }

    private func makeAssertions(preventDisplaySleep: Bool) throws -> [UInt32] {
        var created: [UInt32] = []
        do {
            created.append(try client.create(type: AssertionType.preventIdleSystemSleep, name: "Awake"))
            if let extra = try? client.create(type: AssertionType.preventSystemSleep, name: "Awake") {
                created.append(extra)
            }
            if preventDisplaySleep {
                created.append(try client.create(type: AssertionType.preventDisplaySleep, name: "Awake Display"))
            }
            return created
        } catch {
            let leftover = releaseBestEffort(created)
            if leftover.isEmpty { throw error }
            throw UnreleasedHold(ids: leftover)
        }
    }

    private func releaseBestEffort(_ ids: [UInt32]) -> [UInt32] {
        var leftover: [UInt32] = []
        for id in ids {
            do {
                try client.release(id: id)
            } catch {
                leftover.append(id)
            }
        }
        return leftover
    }
}

private struct UnreleasedHold: Error {
    let ids: [UInt32]
}
