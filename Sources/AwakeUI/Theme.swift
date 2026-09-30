import SwiftUI

/// Shared layout constants, fonts and colors so the popover components stay consistent.
enum Theme {
    static let popoverWidth: CGFloat = 280
    static let popoverPadding: CGFloat = 18
    static let sectionSpacing: CGFloat = 14
    static let iconTileSize: CGFloat = 36
    static let iconTileRadius: CGFloat = 11
    static let animation = Animation.easeInOut(duration: 0.18)

    /// Accent used while sleep is disabled.
    static let active = Color.green

    static let rowTitle = Font.headline
    static let label = Font.callout
    static let secondary = Font.subheadline
    static let footnote = Font.caption
    static let eyebrow = Font.system(size: 10, weight: .semibold, design: .rounded)
}
