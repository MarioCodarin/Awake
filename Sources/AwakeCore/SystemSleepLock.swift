import Foundation

public enum SystemSleepLock {
    public static func isDisabled(in pmsetOutput: String) -> Bool {
        for raw in pmsetOutput.split(whereSeparator: \.isNewline) {
            let compact = raw.split(whereSeparator: \.isWhitespace).joined().lowercased()
            if compact.hasPrefix("sleepdisabled") {
                return compact.hasSuffix("1")
            }
        }
        return false
    }
}

@MainActor
public protocol SystemSleepLockService: AnyObject {
    func isSleepDisabled() -> Bool
    func clearSleepDisabled() throws
}

@MainActor
public final class InMemorySystemSleepLockService: SystemSleepLockService {
    public var disabled: Bool
    public var shouldFailClear = false

    public init(disabled: Bool = false) {
        self.disabled = disabled
    }

    public func isSleepDisabled() -> Bool { disabled }

    public func clearSleepDisabled() throws {
        if shouldFailClear { throw SleepControlError.releaseFailed }
        disabled = false
    }
}

@MainActor
public final class PmsetSystemSleepLockService: SystemSleepLockService {
    public init() {}

    public func isSleepDisabled() -> Bool {
        SystemSleepLock.isDisabled(in: Self.pmsetG())
    }

    public func clearSleepDisabled() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = [
            "-e",
            "do shell script \"pmset -a disablesleep 0\" with administrator privileges"
        ]
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            throw SleepControlError.releaseFailed
        }
    }

    private static func pmsetG() -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}
