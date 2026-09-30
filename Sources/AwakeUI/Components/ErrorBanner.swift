import SwiftUI

/// Dismissible error line. Uses an icon as well as color so it doesn't rely on red alone.
struct ErrorBanner: View {
    let message: String
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .accessibilityHidden(true)
            Text(message)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button(action: dismiss) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss error")
        }
        .font(Theme.footnote)
        .foregroundStyle(.red)
    }
}
