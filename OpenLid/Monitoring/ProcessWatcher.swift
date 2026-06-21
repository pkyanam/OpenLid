import Foundation
import AppKit

/// A running process reduced to the program being executed plus its full command
/// line (for exclude matching).
struct RunningProcess: Equatable {
    /// Lowercased base name of the executable actually being run. For interpreter
    /// launches (e.g. `node /path/codex app-server`) this is the script's name
    /// (`codex`), not the interpreter.
    let program: String
    /// Lowercased full command line, used to test exclude patterns.
    let commandLine: String
}

/// Coarse "is this agent's process alive?" detection. Matches an agent's exact
/// program names against running apps/processes, while ignoring processes whose
/// command line hits an exclude pattern (e.g. always-on `codex app-server` daemons).
enum ProcessWatcher {
    private static let interpreters: Set<String> = [
        "node", "node_repl", "bun", "deno", "python", "python3", "ruby", "npx", "tsx",
    ]

    static func snapshot() -> [RunningProcess] {
        var processes: [RunningProcess] = []

        // GUI apps: program == app name / bundle id; no meaningful command line.
        for app in NSWorkspace.shared.runningApplications {
            if let name = app.localizedName?.lowercased() {
                processes.append(RunningProcess(program: name, commandLine: name))
            }
            if let bundle = app.bundleIdentifier?.lowercased() {
                processes.append(RunningProcess(program: bundle, commandLine: bundle))
            }
        }
        processes.append(contentsOf: cliProcesses())
        return processes
    }

    /// Count of running processes whose program matches one of `names` and whose
    /// command line contains none of `excludes`.
    static func matchCount(names: [String], excludes: [String], in processes: [RunningProcess]) -> Int {
        let needles = Set(names.map { $0.lowercased() })
        let excludeNeedles = excludes.map { $0.lowercased() }
        return processes.filter { proc in
            guard needles.contains(proc.program) else { return false }
            return !excludeNeedles.contains { proc.commandLine.contains($0) }
        }.count
    }

    private static func cliProcesses() -> [RunningProcess] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-axo", "command="]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard let output = String(data: data, encoding: .utf8) else { return [] }
            return output.split(separator: "\n").compactMap { line in
                let command = line.trimmingCharacters(in: .whitespaces)
                guard !command.isEmpty else { return nil }
                return RunningProcess(program: programName(of: command), commandLine: command.lowercased())
            }
        } catch {
            return []
        }
    }

    /// Determine the effective program name for a command line, unwrapping common
    /// interpreters so `node /usr/x/bin/codex app-server` resolves to `codex`.
    private static func programName(of command: String) -> String {
        let tokens = command.split(separator: " ").map(String.init)
        guard let first = tokens.first else { return "" }
        var program = (first as NSString).lastPathComponent.lowercased()
        if interpreters.contains(program) {
            // Use the first non-flag argument (the script being run).
            if let script = tokens.dropFirst().first(where: { !$0.hasPrefix("-") }) {
                program = (script as NSString).lastPathComponent.lowercased()
            }
        }
        return program
    }
}
