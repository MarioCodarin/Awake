import SwiftUI
import AwakeCore

/// Root view of the menu-bar window. Pure layout: every action goes through `SleepModel`.
public struct AwakePopover: View {
    @ObservedObject var model: SleepModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(model: SleepModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
            HeaderView()
            KeepAwakeRow(model: model)
            DurationRow(model: model)
            OptionsSection(model: model)
            if let error = model.errorMessage {
                ErrorBanner(message: error, dismiss: model.dismissError)
            }
            FooterView(helperInstalled: model.helperInstalled)
        }
        .padding(Theme.popoverPadding)
        .frame(width: Theme.popoverWidth)
        .background(.regularMaterial)
        .animation(reduceMotion ? nil : Theme.animation, value: model.keepAwake)
        .onAppear { Task { await model.load() } }
    }
}
