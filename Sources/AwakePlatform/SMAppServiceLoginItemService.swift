import Foundation
import ServiceManagement
import AwakeCore

/// Real `LoginItemService` backed by `SMAppService`.
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
