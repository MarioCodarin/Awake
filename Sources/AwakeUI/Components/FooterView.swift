import SwiftUI

/// Author, version, repository link, and the one-time password note when it still applies.
struct FooterView: View {
    let helperInstalled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Divider()
            Text("Mario Codarin · v\(AppInfo.version)")
                .font(Theme.footnote)
                .foregroundStyle(.secondary)
            if !helperInstalled {
                Text("First toggle asks for your password once to install a helper.")
                    .font(Theme.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Link("github.com/MarioCodarin/Awake", destination: AppInfo.repositoryURL)
                .font(Theme.footnote)
        }
        .padding(.top, 2)
    }
}
