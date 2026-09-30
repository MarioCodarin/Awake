import AppKit
import SwiftUI
import AwakeCore
import AwakePlatform
import AwakeUI

/// Composition root: the only place real services are wired to the model.
@MainActor
enum AppContainer {
    static let model = SleepModel(
        service: AssertionSleepControlService(),
        store: UserDefaultsPreferencesStore(),
        clock: RealSleepClock(),
        loginItem: SMAppServiceLoginItemService(),
        systemLock: PmsetSystemSleepLockService()
    )
}

/// Restores normal sleep before the app exits, so a quit app never leaves the Mac unable to sleep.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        var replied = false
        let reply = {
            guard !replied else { return }
            replied = true
            sender.reply(toApplicationShouldTerminate: true)
        }
        Task { @MainActor in
            await AppContainer.model.shutdown()
            reply()
        }
        // Never let a stuck helper keep the app from quitting.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            reply()
        }
        return .terminateLater
    }
}

@main
struct AwakeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var model = AppContainer.model

    var body: some Scene {
        MenuBarExtra {
            AwakePopover(model: model)
        } label: {
            Image(systemName: model.keepAwake ? "sun.max.fill" : "moon")
                .accessibilityLabel(model.keepAwake ? "Awake: sleep disabled" : "Awake: sleep allowed")
                .task { await model.load() }
        }
        .menuBarExtraStyle(.window)
    }
}
