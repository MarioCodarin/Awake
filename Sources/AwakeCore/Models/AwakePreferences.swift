import Foundation

/// User settings that survive relaunch.
public struct AwakePreferences: Equatable, Sendable {
    /// Last confirmed sleep-disabled state. Informational: the real state is read from `pmset` on launch.
    public var keepAwake: Bool
    public var preventDisplaySleep: Bool
    public var duration: AwakeDuration

    public init(
        keepAwake: Bool = false,
        preventDisplaySleep: Bool = true,
        duration: AwakeDuration = .indefinite
    ) {
        self.keepAwake = keepAwake
        self.preventDisplaySleep = preventDisplaySleep
        self.duration = duration
    }
}
