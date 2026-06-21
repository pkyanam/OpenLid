import Foundation
import AppKit

/// Coarse "is this agent's process alive?" detection. Gathers the set of names of
/// running apps / CLI processes, matched **exactly** (case-insensitive) against an
/// agent's configured names. Exact matching avoids false positives like `cursor`
/// matching `CursorUIViewService` or `code` matching `Xcode`.
enum ProcessWatcher {
    /// Lowercased exact names of every running GUI app (name + bundle id) and the
    /// base command name of every CLI process.
    static func runningNames() -> Set<String> {
        var names = Set<String>()
        for app in NSWorkspace.shared.runningApplications {
            if let name = app.localizedName { names.insert(name.lowercased()) }
            if let bundle = app.bundleIdentifier { names.insert(bundle.lowercased()) }
        }
        for name in cliProcessNames() { names.insert(name) }
        return names
    }

    /// Number of the given names that are currently running (exact, case-insensitive).
    static func matchCount(names: [String], in running: Set<String>) -> Int {
        names.reduce(into: 0) { count, name in
            if running.contains(name.lowercased()) { count += 1 }
        }
    }

    private static func cliProcessNames() -> Set<String> {
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
            var names = Set<String>()
            for line in output.split(separator: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { continue }
                names.insert((trimmed as NSString).lastPathComponent.lowercased())
            }
            return names
        } catch {
            return []
        }
    }
}
