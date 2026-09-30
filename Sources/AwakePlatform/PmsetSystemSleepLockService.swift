import Foundation
import AwakeCore

/// Real `SystemSleepLockService`: reads `pmset -g` and writes through the sudoers-scoped helper.
@MainActor
public final class PmsetSystemSleepLockService: SystemSleepLockService {
    public init() {}

    public var isHelperInstalled: Bool { SystemSleepLock.isHelperInstalled() }

    public func isSleepDisabled() async -> Bool {
        guard let result = try? await ProcessRunner.run("/usr/bin/pmset", ["-g"]) else { return false }
        return SystemSleepLock.isDisabled(in: result.output)
    }

    public func setSleepDisabled(_ disabled: Bool, allowHelperInstall: Bool) async throws {
        let flag = disabled ? "1" : "0"
        if await runHelper(flag: flag) { return }
        guard allowHelperInstall else { throw SystemSleepLockError.helperMissing }
        try await HelperInstaller.install(flag: flag)
        guard await runHelper(flag: flag) else { throw SystemSleepLockError.commandFailed }
    }

    /// `sudo -n` never prompts: it fails fast if the sudoers rule is missing.
    private func runHelper(flag: String) async -> Bool {
        guard SystemSleepLock.isHelperInstalled() else { return false }
        let result = try? await ProcessRunner.run("/usr/bin/sudo", ["-n", SystemSleepLock.helperPath, flag])
        return result?.status == 0
    }
}
