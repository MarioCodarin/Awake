import AppKit
import SwiftUI
import AwakeCore

@main
struct AwakeApp: App {
    @StateObject private var model = SleepModel(
        service: AssertionSleepControlService(),
        store: UserDefaultsPreferencesStore(),
        clock: RealSleepClock(),
        loginItem: SMAppServiceLoginItemService()
    )

    var body: some Scene {
        MenuBarExtra {
            AwakePopover(model: model)
        } label: {
            Image(systemName: model.keepAwake ? "sun.max.fill" : "moon")
                .accessibilityLabel(model.keepAwake ? "Awake: sleep prevented" : "Awake: normal sleep")
                .task { await model.load() }
        }
        .menuBarExtraStyle(.window)
    }
}
