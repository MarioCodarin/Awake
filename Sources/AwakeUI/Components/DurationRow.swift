import SwiftUI
import AwakeCore

/// One-click choice of how long sleep stays disabled.
struct DurationRow: View {
    @ObservedObject var model: SleepModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.space8) {
            Text("Duration")
                .font(Theme.captionStrong)
                .foregroundStyle(.secondary)
            Picker("Duration", selection: Binding(
                get: { model.duration },
                set: { value in Task { await model.setDuration(value) } }
            )) {
                ForEach(AwakeDuration.allCases, id: \.self) { duration in
                    Text(duration.shortTitle)
                        .accessibilityLabel(duration.title)
                        .tag(duration)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .disabled(model.isBusy)
            .accessibilityLabel("Duration")
            .accessibilityHint("How long to keep the Mac awake.")
        }
    }
}

extension AwakeDuration {
    /// Compact label for the segmented control; `title` stays the spoken and tooltip name.
    var shortTitle: String {
        switch self {
        case .indefinite: return "∞"
        case .minutes15: return "15m"
        case .minutes30: return "30m"
        case .hours1: return "1h"
        case .hours2: return "2h"
        }
    }
}
