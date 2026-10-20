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
        HStack(spacing: Theme.space12) {
            Image(systemName: model.keepAwake ? "sun.max.fill" : "moon.fill")
                .font(Theme.glyph)
                .foregroundStyle(model.keepAwake ? Theme.accent : Color.secondary)
                .frame(width: Theme.glyphSize, height: Theme.glyphSize)
                .background(
                    model.keepAwake ? Theme.accent.opacity(0.18) : Color.primary.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: Theme.radiusGlyph, style: .continuous)
                )
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Disable sleep")
                    .font(Theme.title)
                Text(subtitle)
                    .font(Theme.caption)
                    .foregroundStyle(.secondary)
                    .contentTransition(.opacity)
            }
            Spacer(minLength: Theme.space4)
            if model.isBusy {
                ProgressView().controlSize(.small).accessibilityLabel("Updating")
            }
            Toggle("Disable sleep", isOn: Binding(
                get: { model.keepAwake },
                set: { value in Task { await model.setKeepAwake(value) } }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .tint(Theme.accent)
            .controlSize(.small)
            .disabled(model.isBusy)
            .accessibilityValue(subtitle)
            .accessibilityHint("Stops the Mac from sleeping until you turn it off or the timer ends.")
        }
        .padding(Theme.cardPadding)
        .background(
            model.keepAwake ? Theme.cardFillActive : Theme.cardFill,
            in: RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
        )
    }
}
