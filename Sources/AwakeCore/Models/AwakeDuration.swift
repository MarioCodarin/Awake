import Foundation

/// How long Awake keeps the Mac from sleeping before it turns itself off.
public enum AwakeDuration: String, CaseIterable, Equatable, Sendable {
    case indefinite
    case minutes15
    case minutes30
    case hours1
    case hours2

    /// Length of the timer, or `nil` when Awake stays on until turned off.
    public var seconds: TimeInterval? {
        switch self {
        case .indefinite: return nil
        case .minutes15: return 15 * 60
        case .minutes30: return 30 * 60
        case .hours1: return 60 * 60
        case .hours2: return 2 * 60 * 60
        }
    }

    /// Menu title shown in the duration picker.
    public var title: String {
        switch self {
        case .indefinite: return "Indefinite"
        case .minutes15: return "15 minutes"
        case .minutes30: return "30 minutes"
        case .hours1: return "1 hour"
        case .hours2: return "2 hours"
        }
    }
}
