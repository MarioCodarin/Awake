import Foundation
import ServiceManagement

@MainActor
public protocol LoginItemService: AnyObject {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

@MainActor
public final class InMemoryLoginItemService: LoginItemService {
    public private(set) var isEnabled: Bool
    public var shouldFail = false

    public init(isEnabled: Bool = false) {
        self.isEnabled = isEnabled
    }

    public func setEnabled(_ enabled: Bool) throws {
        if shouldFail { throw NSError(domain: "Awake", code: 2) }
        isEnabled = enabled
    }
}

@MainActor
public final class SMAppServiceLoginItemService: LoginItemService {
    public init() {}

    public var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    public func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else if SMAppService.mainApp.status == .enabled {
            try SMAppService.mainApp.unregister()
        }
    }
}
