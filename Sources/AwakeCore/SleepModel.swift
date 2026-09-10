import Combine
import Foundation

@MainActor
public final class SleepModel: ObservableObject {
    @Published public private(set) var keepAwake = false
    @Published public private(set) var isBusy = false
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var preventDisplaySleep = true
    @Published public private(set) var duration: AwakeDuration = .indefinite
    @Published public private(set) var launchAtLogin = false
    @Published public private(set) var systemSleepLocked = false

    private var hasLoaded = false
    private let service: any SleepControlService
    private let store: any PreferencesStore
    private let clock: any SleepClock
    private let loginItem: any LoginItemService
    private let systemLock: any SystemSleepLockService
    private var timerTask: Task<Void, Never>?

    public init(
        service: any SleepControlService,
        store: (any PreferencesStore)? = nil,
        clock: (any SleepClock)? = nil,
        loginItem: (any LoginItemService)? = nil,
        systemLock: (any SystemSleepLockService)? = nil
    ) {
        self.service = service
        self.store = store ?? InMemoryPreferencesStore()
        self.clock = clock ?? RealSleepClock()
        self.loginItem = loginItem ?? InMemoryLoginItemService()
        self.systemLock = systemLock ?? InMemorySystemSleepLockService()
    }

    public func load() async {
        guard !hasLoaded, !isBusy else { return }
        isBusy = true
        let prefs = store.load()
        duration = prefs.duration
        preventDisplaySleep = prefs.preventDisplaySleep
        launchAtLogin = loginItem.isEnabled
        do {
            var shouldStartTimer = false
            if prefs.keepAwake {
                try await service.set(keepAwake: true, preventDisplaySleep: preventDisplaySleep)
                keepAwake = true
                shouldStartTimer = true
            } else {
                keepAwake = try await service.read()
            }
            hasLoaded = true
            errorMessage = nil
            refreshSystemLock()
            persist()
            isBusy = false
            if shouldStartTimer {
                startTimerIfNeeded()
            }
        } catch {
            keepAwake = false
            isBusy = false
            errorMessage = "Couldn’t read the setting. Reopen to retry."
        }
    }

    public func setKeepAwake(_ value: Bool) async {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        do {
            try await service.set(keepAwake: value, preventDisplaySleep: preventDisplaySleep)
            keepAwake = value
            persist()
            refreshSystemLock()
            isBusy = false
            if value {
                startTimerIfNeeded()
            } else {
                cancelTimer()
            }
        } catch {
            isBusy = false
            errorMessage = "Couldn’t update. Try again."
        }
    }

    public func setPreventDisplaySleep(_ value: Bool) async {
        let previous = preventDisplaySleep
        preventDisplaySleep = value
        guard keepAwake, !isBusy else {
            persist()
            return
        }
        isBusy = true
        errorMessage = nil
        do {
            try await service.set(keepAwake: true, preventDisplaySleep: value)
            persist()
            isBusy = false
        } catch {
            preventDisplaySleep = previous
            isBusy = false
            errorMessage = "Couldn’t update. Try again."
        }
    }

    public func setDuration(_ value: AwakeDuration) async {
        duration = value
        persist()
        guard keepAwake else { return }
        startTimerIfNeeded()
    }

    public func unlockSystemSleep() {
        do {
            try systemLock.clearSleepDisabled()
            refreshSystemLock()
            if systemSleepLocked {
                errorMessage = "Couldn’t unlock Apple Sleep. Try again."
            } else {
                errorMessage = nil
            }
        } catch {
            refreshSystemLock()
            errorMessage = "Password required to unlock Apple Sleep."
        }
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

    public func waitForTimer() async {
        await timerTask?.value
    }

    private func refreshSystemLock() {
        systemSleepLocked = systemLock.isSleepDisabled()
    }

    private func persist() {
        store.save(
            AwakePreferences(
                keepAwake: keepAwake,
                preventDisplaySleep: preventDisplaySleep,
                duration: duration
            )
        )
    }

    private func cancelTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func startTimerIfNeeded() {
        cancelTimer()
        guard let seconds = duration.seconds else { return }
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

    private func expireTimer() async {
        timerTask = nil
        await setKeepAwake(false)
    }
}
