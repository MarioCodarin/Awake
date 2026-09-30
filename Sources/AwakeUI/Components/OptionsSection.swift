import SwiftUI
import AwakeCore

/// Checkbox options: keep the display on, and launch at login.
struct OptionsSection: View {
    @ObservedObject var model: SleepModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(
                "Keep display on",
                isOn: Binding(
                    get: { model.preventDisplaySleep },
                    set: { value in Task { await model.setPreventDisplaySleep(value) } }
                )
            )
            .font(Theme.label)
            .toggleStyle(.checkbox)
            .controlSize(.small)
            .disabled(model.isBusy)
            .accessibilityHint("When off, the display may sleep while the Mac stays awake.")

            VStack(alignment: .leading, spacing: 3) {
                Toggle(
                    "Launch at login",
                    isOn: Binding(
                        get: { model.launchAtLogin },
                        set: { model.setLaunchAtLogin($0) }
                    )
                )
                .font(Theme.label)
                .toggleStyle(.checkbox)
                .controlSize(.small)
                if !AppInfo.isInApplications {
                    Text("Move Awake to Applications for this to work reliably.")
                        .font(Theme.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
