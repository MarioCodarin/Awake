import SwiftUI

/// Single home for the popover's spacing, radii, type, color and motion.
/// Spacing follows a 4 pt grid; change a value here and every component follows.
enum Theme {
    // MARK: Spacing (4 pt grid)
    static let space4: CGFloat = 4
    static let space8: CGFloat = 8
    static let space12: CGFloat = 12
    static let space16: CGFloat = 16

    // MARK: Layout
    static let popoverWidth: CGFloat = 288
    static let popoverPadding = space16
    static let sectionSpacing = space12
    static let cardPadding = space12
    static let glyphSize: CGFloat = 36
    static let rowHeight: CGFloat = 24

    // MARK: Radii
    static let radiusCard: CGFloat = 12
    static let radiusGlyph: CGFloat = 10
    static let radiusControl: CGFloat = 6

    // MARK: Typography (system fonts only)
    static let title = Font.system(size: 13, weight: .semibold)
    static let body = Font.system(size: 13)
    static let caption = Font.system(size: 11)
    static let captionStrong = Font.system(size: 11, weight: .medium)
    static let glyph = Font.system(size: 17, weight: .medium)

    // MARK: Color — one accent (sun amber) plus semantic neutrals
    static let accent = Color.orange
    static let cardFill = Color.primary.opacity(0.05)
    static let cardFillActive = Color.orange.opacity(0.14)
    static let hoverFill = Color.primary.opacity(0.08)
    static let pressedFill = Color.primary.opacity(0.14)
    static let danger = Color.red

    // MARK: Motion (150–250 ms)
    static let animation = Animation.easeOut(duration: 0.18)
    static let hoverAnimation = Animation.easeOut(duration: 0.12)
}

/// Quiet text/icon button: no chrome until hovered, tinted while pressed.
struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        QuietButtonBody(configuration: configuration)
    }
}

/// Hover flag as an object: `@State` needs a macro plugin that command-line toolchains lack.
private final class HoverFlag: ObservableObject {
    @Published var isHovering = false
}

private struct QuietButtonBody: View {
    let configuration: ButtonStyleConfiguration
    @StateObject private var hover = HoverFlag()

    var body: some View {
        configuration.label
            .padding(.horizontal, Theme.space8)
            .frame(minHeight: Theme.rowHeight)
            .background(
                configuration.isPressed ? Theme.pressedFill : (hover.isHovering ? Theme.hoverFill : .clear),
                in: RoundedRectangle(cornerRadius: Theme.radiusControl, style: .continuous)
            )
            .contentShape(Rectangle())
            .onHover { hover.isHovering = $0 }
            .animation(Theme.hoverAnimation, value: hover.isHovering)
    }
}
