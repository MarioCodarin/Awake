import SwiftUI

/// Dismissible error. Uses an icon as well as color so it doesn't rely on red alone.
struct ErrorBanner: View {
    let message: String
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.space8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .accessibilityHidden(true)
            Text(message)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Dismiss")
            .accessibilityLabel("Dismiss error")
        }
        .font(Theme.caption)
        .foregroundStyle(Theme.danger)
        .padding(.horizontal, Theme.space12)
        .padding(.vertical, Theme.space8)
        .background(
            Theme.danger.opacity(0.12),
            in: RoundedRectangle(cornerRadius: Theme.radiusControl + 2, style: .continuous)
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}
