import Foundation

/// Registers the app to launch at login.
@MainActor
public protocol LoginItemService: AnyObject {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}
