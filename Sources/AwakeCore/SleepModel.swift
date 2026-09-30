import Combine
import Foundation

/// Single source of truth for the popover. Owns the sleep state, the duration timer and preferences,
/// and talks to the system only through injected services.
///
/// State rules:
/// - `keepAwake` always mirrors the confirmed `pmset` flag; a failed write leaves it unchanged.
/// - Writes are ignored while `isBusy`.
/// - A duration timer is armed only when sleep turns off→on or the duration changes, never by `load()`.
@MainActor
public final class SleepModel: ObservableObject {
    @Published public private(set) var keepAwake = false
    @Published public private(set) var isBusy = false
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var preventDisplaySleep = true
    @Published public private(set) var duration: AwakeDuration = .indefinite
    @Published public private(set) var launchAtLogin = false
    @Published public private(set) var helperInstalled = false
    /// When the running timer will turn sleep prevention off; `nil` if no timer is running.
    @Published public private(set) var endDate: Date?

    private var hasLoaded = false
    private var expiryPending = false
    private var timerTask: Task<Void, Never>?
    private let service: any SleepControlService
    private let store: any PreferencesStore
    private let clock: any SleepClock
    private let loginItem: any LoginItemService
    private let systemLock: any SystemSleepLockService
    private let now: () -> Date

    public init(
        service: any SleepControlService,
        store: any PreferencesStore,
        clock: any SleepClock,
        loginItem: any LoginItemService,
        systemLock: any SystemSleepLockService,
        now: @escaping () -> Date = Date.init
    ) {
        self.service = service
        self.store = store
        self.clock = clock
        self.loginItem = loginItem
        self.systemLock = systemLock
        self.now = now
    }

    // MARK: - Loading

    /// Syncs the model with the system. Safe to call whenever the popover opens; it does not
    /// restart a running timer.
    public func load() async {
        guard !isBusy else { return }
        beginBusy()
        if !hasLoaded {
            let prefs = store.load()
            duration = prefs.duration
            preventDisplaySleep = prefs.preventDisplaySleep
            hasLoaded = true
        }
        launchAtLogin = loginItem.isEnabled
        let disabled = await systemLock.isSleepDisabled()
        helperInstalled = systemLock.isHelperInstalled
        keepAwake = disabled
        do {
            if (try? await service.read()) != disabled {
                try await service.set(keepAwake: disabled, preventDisplaySleep: preventDisplaySleep)
            }
            errorMessage = nil
            persist()
            endBusy()
            syncTimer(restart: false)
        } catch {
            endBusy()
            errorMessage = "Couldn’t update idle sleep. Apple Sleep still follows pmset."
        }
    }

    // MARK: - Intents

    public func setKeepAwake(_ value: Bool) async {
        await applyKeepAwake(value, allowHelperInstall: true)
    }

    public func setPreventDisplaySleep(_ value: Bool) async {
        let previous = preventDisplaySleep
        preventDisplaySleep = value
        guard keepAwake, !isBusy else {
            persist()
            return
        }
        beginBusy()
        errorMessage = nil
        do {
            try await service.set(keepAwake: true, preventDisplaySleep: value)
            persist()
            endBusy()
        } catch {
            preventDisplaySleep = previous
            endBusy()
            errorMessage = "Couldn’t update. Try again."
        }
    }

    public func setDuration(_ value: AwakeDuration) async {
        duration = value
        persist()
        guard keepAwake else { return }
        syncTimer(restart: true)
    }

    public func setLaunchAtLogin(_ value: Bool) {
        do {
            try loginItem.setEnabled(value)
            launchAtLogin = loginItem.isEnabled
            errorMessage = nil
        } catch {
            launchAtLogin = loginItem.isEnabled
            errorMessage = "Couldn’t update login item. Try again."
        }
    }

    public func dismissError() {
        errorMessage = nil
    }

    /// Restores normal sleep before the app quits. Never prompts for a password: if the helper
    /// is not installed, the flag was never changed by this app.
    public func shutdown() async {
        cancelTimer()
        if keepAwake {
            try? await systemLock.setSleepDisabled(false, allowHelperInstall: false)
            keepAwake = await systemLock.isSleepDisabled()
        }
        try? await service.set(keepAwake: false, preventDisplaySleep: preventDisplaySleep)
        persist()
    }

    /// Suspends until the running timer finishes. For tests.
    public func waitForTimer() async {
        await timerTask?.value
    }

    // MARK: - Sleep flag

    private func applyKeepAwake(_ value: Bool, allowHelperInstall: Bool) async {
        guard !isBusy else { return }
        beginBusy()
        errorMessage = nil
        let wasOn = keepAwake
        do {
            try await systemLock.setSleepDisabled(value, allowHelperInstall: allowHelperInstall)
            keepAwake = await systemLock.isSleepDisabled()
            helperInstalled = systemLock.isHelperInstalled
            persist()
            try? await service.set(keepAwake: keepAwake, preventDisplaySleep: preventDisplaySleep)
            endBusy()
            syncTimer(restart: keepAwake && !wasOn)
            if keepAwake != value {
                errorMessage = "Couldn’t change Apple Sleep. Try again."
            }
        } catch {
            keepAwake = await systemLock.isSleepDisabled()
            helperInstalled = systemLock.isHelperInstalled
            endBusy()
            errorMessage = Self.message(for: error)
        }
    }

    private static func message(for error: Error) -> String {
        switch error as? SystemSleepLockError {
        case .installCancelled:
            return "Password cancelled. Sleep setting unchanged."
        case .helperMissing:
            return "Sleep helper is not installed. Toggle Disable sleep to install it."
        default:
            return "Couldn’t change Apple Sleep. Try again."
        }
    }

    // MARK: - Busy tracking

    private func beginBusy() {
        isBusy = true
    }

    /// Clears `isBusy` and applies a timer expiry that arrived while a write was in flight.
    private func endBusy() {
        isBusy = false
        if expiryPending {
            expiryPending = false
            Task { await expireTimer() }
        }
    }

    // MARK: - Timer

    private func persist() {
        store.save(
            AwakePreferences(
                keepAwake: keepAwake,
                preventDisplaySleep: preventDisplaySleep,
                duration: duration
            )
        )
    }

    /// Makes the timer match the state: off when sleep is allowed or the duration is indefinite,
    /// otherwise armed. A running timer is kept unless `restart` is true.
    private func syncTimer(restart: Bool) {
        guard keepAwake, let seconds = duration.seconds else {
            cancelTimer()
            return
        }
        if restart || timerTask == nil {
            armTimer(seconds: seconds)
        }
    }

    private func armTimer(seconds: TimeInterval) {
        cancelTimer()
        endDate = now().addingTimeInterval(seconds)
        let clock = self.clock
        timerTask = Task { [weak self] in
            do {
                try await clock.sleep(seconds: seconds)
                guard !Task.isCancelled else { return }
                await self?.expireTimer()
            } catch {
                return
            }
        }
    }

    private func cancelTimer() {
        timerTask?.cancel()
        timerTask = nil
        endDate = nil
        expiryPending = false
    }

    private func expireTimer() async {
        timerTask = nil
        endDate = nil
        guard keepAwake else { return }
        if isBusy {
            expiryPending = true
            return
        }
        await applyKeepAwake(false, allowHelperInstall: false)
    }
}
