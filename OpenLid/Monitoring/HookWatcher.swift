import Foundation

/// Watches `~/.openlid/agents/` for status files written by agent lifecycle hooks.
///
/// File contract (per session): `<agent-id>-<session>.json` containing
/// `{"agent":"<agent-id>","status":"working"}`. A file is treated as idle once it
/// is deleted, rewritten with a non-"working" status, or grows stale (mtime older
/// than `staleAfter`) so a crashed hook never holds the lock forever.
final class HookWatcher {
    static var agentsDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".openlid", isDirectory: true)
            .appendingPathComponent("agents", isDirectory: true)
    }

    private var source: DispatchSourceFileSystemObject?
    private var dirFD: Int32 = -1

    init() { ensureDirectory() }

    private func ensureDirectory() {
        try? FileManager.default.createDirectory(at: Self.agentsDirectory, withIntermediateDirectories: true)
    }

    private struct HookFile: Decodable {
        var agent: String?
        var status: String?
    }

    /// Count of working sessions per agentID. Absent agents have 0 working sessions.
    func workingSessions(staleAfter: TimeInterval) -> [String: Int] {
        ensureDirectory()
        var counts: [String: Int] = [:]
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: Self.agentsDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return counts }

        let now = Date()
        for file in files where file.pathExtension == "json" {
            let mtime = (try? file.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            if now.timeIntervalSince(mtime) > staleAfter { continue }   // stale -> treat as idle

            guard let data = try? Data(contentsOf: file) else { continue }
            let parsed = try? JSONDecoder().decode(HookFile.self, from: data)
            let status = (parsed?.status ?? "working").lowercased()
            guard status == "working" else { continue }

            // Prefer the agent id from the file; otherwise derive from "<agent-id>-<session>".
            let agentID = parsed?.agent ?? Self.agentID(fromFileName: file.deletingPathExtension().lastPathComponent)
            counts[agentID, default: 0] += 1
        }
        return counts
    }

    private static func agentID(fromFileName name: String) -> String {
        if let dash = name.lastIndex(of: "-") { return String(name[..<dash]) }
        return name
    }

    /// Fire `onChange` whenever the directory contents change (for snappy UI updates).
    func startWatching(onChange: @escaping () -> Void) {
        stopWatching()
        ensureDirectory()
        dirFD = open(Self.agentsDirectory.path, O_EVTONLY)
        guard dirFD >= 0 else { return }
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: dirFD, eventMask: [.write, .delete, .rename], queue: .main)
        src.setEventHandler(handler: onChange)
        src.setCancelHandler { [weak self] in
            if let fd = self?.dirFD, fd >= 0 { close(fd) }
            self?.dirFD = -1
        }
        src.resume()
        source = src
    }

    func stopWatching() {
        source?.cancel()
        source = nil
    }

    deinit { stopWatching() }
}
