import AppKit
import SwiftUI

/// Wordmark and Quit button.
struct HeaderView: View {
    var body: some View {
        HStack(spacing: 6) {
            Text("AWAKE")
                .font(Theme.eyebrow)
                .tracking(2)
                .foregroundStyle(.secondary)
            Spacer()
            Button { NSApplication.shared.terminate(nil) } label: {
                Image(systemName: "power")
                    .font(.system(size: 11, weight: .medium))
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Quit Awake and allow sleep")
            .accessibilityLabel("Quit Awake")
            .keyboardShortcut("q")
        }
    }
}
