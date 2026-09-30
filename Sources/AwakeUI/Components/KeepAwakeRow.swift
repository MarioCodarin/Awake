import SwiftUI
import AwakeCore

/// Main switch. The subtitle is the single place that states the current status and end time.
struct KeepAwakeRow: View {
    @ObservedObject var model: SleepModel

    private var subtitle: String {
        guard model.keepAwake else { return "Mac can sleep normally" }
        guard let end = model.endDate else { return "Until you turn it off" }
        return "Until \(end.formatted(date: .omitted, time: .shortened))"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: model.keepAwake ? "sun.max.fill" : "moon.fill")
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(model.keepAwake ? Theme.active : Color.secondary)
                .frame(width: Theme.iconTileSize, height: Theme.iconTileSize)
                .background(
                    model.keepAwake ? Theme.active.opacity(0.12) : Color.primary.opacity(0.05),
                    in: RoundedRectangle(cornerRadius: Theme.iconTileRadius)
                )
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("Disable sleep")
                    .font(Theme.rowTitle)
                Text(subtitle)
                    .font(Theme.secondary)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            if model.isBusy {
                ProgressView().controlSize(.small).accessibilityLabel("Updating")
            }
            Toggle("Disable sleep", isOn: Binding(
                get: { model.keepAwake },
                set: { value in Task { await model.setKeepAwake(value) } }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .tint(Theme.active)
            .controlSize(.small)
            .disabled(model.isBusy)
            .accessibilityValue(subtitle)
            .accessibilityHint("Stops the Mac from sleeping until you turn it off or the timer ends.")
        }
    }
}
