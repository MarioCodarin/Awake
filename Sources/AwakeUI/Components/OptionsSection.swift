import SwiftUI
import AwakeCore

/// Switch rows: keep the display on, and launch at login.
struct OptionsSection: View {
    @ObservedObject var model: SleepModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.space4) {
            OptionRow(
                title: "Keep display on",
                isOn: Binding(
                    get: { model.preventDisplaySleep },
                    set: { value in Task { await model.setPreventDisplaySleep(value) } }
                ),
                disabled: model.isBusy,
                hint: "When off, the display may sleep while the Mac stays awake."
            )
            OptionRow(
                title: "Launch at login",
                isOn: Binding(
                    get: { model.launchAtLogin },
                    set: { model.setLaunchAtLogin($0) }
                ),
                disabled: false,
                hint: "Opens Awake when you log in."
            )
            if !AppInfo.isInApplications {
                Text("Move Awake to Applications for this to work reliably.")
                    .font(Theme.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct OptionRow: View {
    let title: String
    @Binding var isOn: Bool
    let disabled: Bool
    let hint: String

    var body: some View {
        HStack {
            Text(title).font(Theme.body)
            Spacer(minLength: Theme.space8)
            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(Theme.accent)
                .controlSize(.mini)
                .disabled(disabled)
        }
        .frame(minHeight: Theme.rowHeight)
        .accessibilityElement(children: .combine)
        .accessibilityHint(hint)
    }
}
