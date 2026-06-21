import Foundation

/// How OpenLid detects whether a given agent is working.
enum AgentDetection: Codable, Equatable, Hashable {
    /// Watch for a running process / application by name. Coarse: "alive == maybe working".
    case process(names: [String])
    /// Watch `~/.openlid/agents/` for status files written by the agent's lifecycle hooks.
    /// High accuracy: real Working/Idle per session.
    case hook(agentID: String)

    var isHook: Bool {
        if case .hook = self { return true }
        return false
    }
}

/// A configured agent OpenLid watches. Persisted to config.json.
struct Agent: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var name: String
    var detection: AgentDetection
    /// SF Symbol used as the row icon (we can't bundle third-party logos).
    var symbol: String
    var enabled: Bool

    init(id: String, name: String, detection: AgentDetection, symbol: String, enabled: Bool = true) {
        self.id = id
        self.name = name
        self.detection = detection
        self.symbol = symbol
        self.enabled = enabled
    }
}

/// Live, non-persisted status for an agent, shown in the menu bar dropdown.
struct AgentStatus: Identifiable, Equatable {
    let id: String
    let name: String
    let symbol: String
    var isWorking: Bool
    /// Number of active sessions (hook agents). For process agents this is the
    /// number of matching processes found.
    var sessionCount: Int

    var statusLabel: String {
        if isWorking {
            if sessionCount > 1 { return "\(sessionCount) sessions" }
            return sessionCount == 1 ? "1 session" : "working"
        }
        return "idle"
    }
}
