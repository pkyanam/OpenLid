import Foundation

/// How OpenLid detects whether an agent is working.
///
/// An agent may use a lifecycle **hook** (accurate, per-session), a **process** name
/// fallback (coarse: "the process is alive"), or both. When both are configured the
/// hook signal wins; the process name is only a fallback so agents still light up
/// even before their hooks are installed.
struct AgentDetection: Codable, Equatable, Hashable {
    /// Hook id watched in `~/.openlid/agents/` (file-based signaling). High accuracy.
    var hookID: String?
    /// Exact program names to match (case-insensitive) against the executable being
    /// run (interpreter-aware) and GUI app names. Coarse fallback.
    var processNames: [String]
    /// If a matching process's full command line contains any of these substrings,
    /// it's ignored. Used to skip always-on daemons (e.g. `codex app-server` spawned
    /// by other tools) so they don't look like an active session.
    var excludeProcessPatterns: [String]

    init(hookID: String? = nil, processNames: [String] = [], excludeProcessPatterns: [String] = []) {
        self.hookID = hookID
        self.processNames = processNames
        self.excludeProcessPatterns = excludeProcessPatterns
    }

    var usesHook: Bool { hookID != nil }
    var usesProcess: Bool { !processNames.isEmpty }

    // Tolerant decoding so older configs (without the newer keys) still load.
    private enum CodingKeys: String, CodingKey { case hookID, processNames, excludeProcessPatterns }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        hookID = try c.decodeIfPresent(String.self, forKey: .hookID)
        processNames = try c.decodeIfPresent([String].self, forKey: .processNames) ?? []
        excludeProcessPatterns = try c.decodeIfPresent([String].self, forKey: .excludeProcessPatterns) ?? []
    }
}

/// A configured agent OpenLid watches. Persisted to config.json.
struct Agent: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var name: String
    var detection: AgentDetection
    /// Asset-catalog image name for the agent's brand icon.
    var iconName: String
    var enabled: Bool

    init(id: String, name: String, detection: AgentDetection, iconName: String, enabled: Bool = true) {
        self.id = id
        self.name = name
        self.detection = detection
        self.iconName = iconName
        self.enabled = enabled
    }
}

/// Live, non-persisted status for an agent, shown in the menu bar dropdown.
struct AgentStatus: Identifiable, Equatable {
    let id: String
    let name: String
    let iconName: String
    var isWorking: Bool
    /// Hook sessions when detected via hook; matching process count otherwise.
    var sessionCount: Int
    /// True when the working signal came from a hook (accurate), false for process.
    var detectedViaHook: Bool

    var statusLabel: String {
        guard isWorking else { return "idle" }
        if detectedViaHook {
            if sessionCount > 1 { return "\(sessionCount) sessions" }
            return sessionCount == 1 ? "1 session" : "working"
        }
        return "running"
    }
}
