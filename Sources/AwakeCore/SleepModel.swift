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
        guard !isBusy else { return }
        isBusy = true
        if !hasLoaded {
            let prefs = store.load()
            duration = prefs.duration
            preventDisplaySleep = prefs.preventDisplaySleep
            launchAtLogin = loginItem.isEnabled
        }
        let disabled = systemLock.isSleepDisabled()
        keepAwake = disabled
        systemSleepLocked = disabled
        do {
            try await service.set(keepAwake: disabled, preventDisplaySleep: preventDisplaySleep)
            hasLoaded = true
            errorMessage = nil
            persist()
            isBusy = false
            if disabled {
                startTimerIfNeeded()
            } else {
                cancelTimer()
            }
        } catch {
            isBusy = false
            errorMessage = "Couldn’t update idle sleep. Apple Sleep still follows pmset."
        }
    }

    public func setKeepAwake(_ value: Bool) async {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        do {
            try systemLock.setSleepDisabled(value)
            keepAwake = systemLock.isSleepDisabled()
            systemSleepLocked = keepAwake
            persist()
            try? await service.set(keepAwake: keepAwake, preventDisplaySleep: preventDisplaySleep)
            isBusy = false
            if keepAwake {
                startTimerIfNeeded()
            } else {
                cancelTimer()
            }
            if keepAwake != value {
                errorMessage = "Couldn’t change Apple Sleep. Try again."
            }
        } catch {
            keepAwake = systemLock.isSleepDisabled()
            systemSleepLocked = keepAwake
            isBusy = false
            errorMessage = "macOS password needed to set disablesleep \(value ? "1" : "0")."
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
        Task { await setKeepAwake(false) }
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
