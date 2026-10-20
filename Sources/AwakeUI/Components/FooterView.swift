import AppKit
import SwiftUI

/// Version, repository link and Quit, plus the one-time password note when it still applies.
struct FooterView: View {
    let helperInstalled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.space8) {
            if !helperInstalled {
                Text("The first change asks for your password once.")
                    .font(Theme.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Divider()
            HStack(spacing: 0) {
                Link(destination: AppInfo.repositoryURL) {
                    Text("Awake \(AppInfo.version)")
                        .font(Theme.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(QuietButtonStyle())
                .help("Awake by Mario Codarin — open GitHub")
                Spacer()
                Button { NSApplication.shared.terminate(nil) } label: {
                    HStack(spacing: Theme.space4) {
                        Text("Quit")
                        Text("⌘Q").foregroundStyle(.tertiary)
                    }
                    .font(Theme.caption)
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(QuietButtonStyle())
                .keyboardShortcut("q")
                .help("Quit Awake and allow sleep")
                .accessibilityLabel("Quit Awake")
            }
            .padding(.horizontal, -Theme.space8)
        }
    }
}
