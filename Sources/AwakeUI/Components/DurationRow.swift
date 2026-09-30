import SwiftUI
import AwakeCore

/// Picker for how long sleep stays disabled.
struct DurationRow: View {
    @ObservedObject var model: SleepModel

    var body: some View {
        HStack {
            Text("Duration")
                .font(Theme.label)
            Spacer()
            Picker("Duration", selection: Binding(
                get: { model.duration },
                set: { value in Task { await model.setDuration(value) } }
            )) {
                ForEach(AwakeDuration.allCases, id: \.self) { duration in
                    Text(duration.title).tag(duration)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .controlSize(.small)
            .disabled(model.isBusy)
            .accessibilityHint("How long to keep the Mac awake.")
        }
    }
}
