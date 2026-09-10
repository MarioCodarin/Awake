import Foundation
import IOKit.pwr_mgt

public enum AssertionType {
    public static let preventDisplaySleep = kIOPMAssertionTypePreventUserIdleDisplaySleep as String
    public static let preventSystemSleep = kIOPMAssertionTypePreventUserIdleSystemSleep as String
}

public enum SleepControlError: Error, Equatable {
    case assertionFailed(Int32)
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
    private var assertionID: UInt32?

    public init(client: any AssertionClient = IOKitAssertionClient()) {
        self.client = client
    }

    public func read() async throws -> Bool {
        assertionID != nil
    }

    public func set(keepAwake: Bool, preventDisplaySleep: Bool) async throws {
        if let existing = assertionID {
            try client.release(id: existing)
            assertionID = nil
        }
        guard keepAwake else { return }
        let type = preventDisplaySleep ? AssertionType.preventDisplaySleep : AssertionType.preventSystemSleep
        assertionID = try client.create(type: type, name: "Awake")
    }

    deinit {
        if let assertionID {
            try? client.release(id: assertionID)
        }
    }
}
