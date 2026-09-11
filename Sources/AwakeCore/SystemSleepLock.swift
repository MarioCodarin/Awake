import Foundation

public enum SystemSleepLock {
    public static let helperPath = "/Library/PrivilegedHelperTools/com.mariocodarin.Awake.pmset"

    public static func isDisabled(in pmsetOutput: String) -> Bool {
        for raw in pmsetOutput.split(whereSeparator: \.isNewline) {
            let compact = raw.split(whereSeparator: \.isWhitespace).joined().lowercased()
            if compact.hasPrefix("sleepdisabled") {
                return compact.hasSuffix("1")
            }
        }
        return false
    }

    public static func sudoersLine(user: String) -> String {
        "\(user) ALL=(root) NOPASSWD: \(helperPath) 0, \(helperPath) 1"
    }

    public static func isHelperInstalled(fileExists: (String) -> Bool = { FileManager.default.isExecutableFile(atPath: $0) }) -> Bool {
        fileExists(helperPath)
    }
}

@MainActor
public protocol SystemSleepLockService: AnyObject {
    func isSleepDisabled() -> Bool
    func setSleepDisabled(_ disabled: Bool) throws
}

@MainActor
public final class InMemorySystemSleepLockService: SystemSleepLockService {
    public var disabled: Bool
    public var shouldFailSet = false

    public init(disabled: Bool = false) {
        self.disabled = disabled
    }

    public func isSleepDisabled() -> Bool { disabled }

    public func setSleepDisabled(_ disabled: Bool) throws {
        if shouldFailSet { throw SleepControlError.releaseFailed }
        self.disabled = disabled
    }
}

@MainActor
public final class PmsetSystemSleepLockService: SystemSleepLockService {
    public init() {}

    public func isSleepDisabled() -> Bool {
        SystemSleepLock.isDisabled(in: Self.pmsetG())
    }

    public func setSleepDisabled(_ disabled: Bool) throws {
        let flag = disabled ? "1" : "0"
        if Self.runHelper(flag: flag) { return }
        try Self.installHelper(flag: flag)
        guard Self.runHelper(flag: flag) else {
            throw SleepControlError.releaseFailed
        }
    }

    private static func runHelper(flag: String) -> Bool {
        guard SystemSleepLock.isHelperInstalled() else { return false }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments = ["-n", SystemSleepLock.helperPath, flag]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    private static func installHelper(flag: String) throws {
        guard let installer = installerURL() else {
            throw SleepControlError.releaseFailed
        }
        let user = NSUserName()
        let source = """
        set installer to "\(installer.path)"
        set uname to "\(user)"
        set flag to "\(flag)"
        do shell script (quoted form of installer) & " " & (quoted form of uname) & " " & flag with administrator privileges
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", source]
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            throw SleepControlError.releaseFailed
        }
    }

    private static func installerURL() -> URL? {
        if let bundled = Bundle.main.url(forResource: "install-awake-helper", withExtension: "sh") {
            return bundled
        }
        let nextToApp = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Resources/install-awake-helper.sh")
        if FileManager.default.isReadableFile(atPath: nextToApp.path) {
            return nextToApp
        }
        return nil
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
