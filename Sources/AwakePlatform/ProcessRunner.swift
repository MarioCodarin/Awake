import Foundation

struct ProcessResult {
    let status: Int32
    /// Standard output and standard error, merged.
    let output: String
}

/// Runs a child process off the main thread so the menu-bar UI never blocks on `pmset`,
/// `sudo` or the administrator password prompt.
enum ProcessRunner {
    static func run(_ executable: String, _ arguments: [String]) async throws -> ProcessResult {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executable)
                process.arguments = arguments
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe
                do {
                    try process.run()
                    // Drain before waiting, or a full pipe would deadlock the child.
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    process.waitUntilExit()
                    continuation.resume(returning: ProcessResult(
                        status: process.terminationStatus,
                        output: String(data: data, encoding: .utf8) ?? ""
                    ))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
