import Foundation
import AppKit

/// Coarse "is this agent's process alive?" detection. Gathers a list of tokens
/// (one per running app / CLI process) that agent name patterns are matched against.
enum ProcessWatcher {
    /// Lowercased tokens for every running GUI app (name + bundle id) and CLI process.
    static func runningTokens() -> [String] {
        var tokens: [String] = []

        for app in NSWorkspace.shared.runningApplications {
            if let name = app.localizedName { tokens.append(name.lowercased()) }
            if let bundle = app.bundleIdentifier { tokens.append(bundle.lowercased()) }
        }
        tokens.append(contentsOf: cliProcessNames())
        return tokens
    }

    /// Number of tokens that match any of the given names (case-insensitive substring).
    static func matchCount(names: [String], in tokens: [String]) -> Int {
        let needles = names.map { $0.lowercased() }
        return tokens.filter { token in needles.contains { token.contains($0) } }.count
    }

    private static func cliProcessNames() -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-axo", "comm="]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard let output = String(data: data, encoding: .utf8) else { return [] }
            return output
                .split(separator: "\n")
                .map { line -> String in
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    return (trimmed as NSString).lastPathComponent.lowercased()
                }
        } catch {
            return []
        }
    }
}
