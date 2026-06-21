import Foundation

/// All user-facing settings. Persisted as JSON to
/// `~/Library/Application Support/OpenLid/config.json`.
struct AppConfig: Codable, Equatable {
    // MARK: Core
    /// Master on/off (the header toggle and ⌥⌘L shortcut).
    var globalEnabled: Bool = true
    /// Seconds to wait after all agents go idle before allowing sleep.
    var idleTimeoutSeconds: Int = 30
    /// When agents finish (or battery limit hit), actively ask the Mac to sleep.
    var autoSleep: Bool = true

    // MARK: Battery guardrails
    var onlyWhenPluggedIn: Bool = false
    var batteryCutoffEnabled: Bool = true
    var batteryCutoffPercent: Int = 20
    var respectLowPowerMode: Bool = true

    // MARK: Display control
    var displayOffWhileWorking: Bool = false
    /// 0 == disabled. Turn the display off N seconds after agents finish.
    var displayOffAfterFinishSeconds: Int = 0

    // MARK: Notifications
    var notificationsEnabled: Bool = true
    var soundsEnabled: Bool = true

    // MARK: Agents
    var agents: [Agent] = AppConfig.defaultAgents

    static let defaultAgents: [Agent] = [
        Agent(id: "claude-code", name: "Claude Code",
              detection: AgentDetection(hookID: "claude-code", processNames: ["claude"]),
              iconName: "agent.claude"),
        Agent(id: "codex", name: "OpenAI Codex CLI",
              detection: AgentDetection(hookID: "codex", processNames: ["codex"],
                                        excludeProcessPatterns: ["app-server"]),
              iconName: "agent.openai"),
        Agent(id: "opencode", name: "OpenCode",
              detection: AgentDetection(hookID: "opencode", processNames: ["opencode"]),
              iconName: "agent.opencode"),
        Agent(id: "antigravity", name: "Antigravity",
              detection: AgentDetection(hookID: "antigravity",
                                        processNames: ["Antigravity", "Antigravity IDE"]),
              iconName: "agent.antigravity"),
        Agent(id: "devin", name: "Devin",
              detection: AgentDetection(hookID: "devin", processNames: ["devin"]),
              iconName: "agent.devin"),
        Agent(id: "hermes", name: "Hermes",
              detection: AgentDetection(hookID: "hermes", processNames: ["hermes"]),
              iconName: "agent.hermes"),
        Agent(id: "cursor", name: "Cursor",
              detection: AgentDetection(processNames: ["Cursor"]),
              iconName: "agent.cursor"),
    ]

    /// Reconcile persisted agents with the current built-in defaults: built-in
    /// detection rules, names and icons always come from code (so improvements ship
    /// without wiping the user's config), while the user's `enabled` toggles and any
    /// custom agents are preserved.
    func normalized() -> AppConfig {
        var result = self
        let defaultIDs = Set(AppConfig.defaultAgents.map(\.id))
        var merged: [Agent] = AppConfig.defaultAgents.map { def in
            guard let existing = agents.first(where: { $0.id == def.id }) else { return def }
            var refreshed = def
            refreshed.enabled = existing.enabled
            return refreshed
        }
        // Preserve only genuinely user-added agents (the "custom-" prefix we assign).
        // Anything else that isn't a current default is a removed/renamed built-in
        // (e.g. the deprecated "gemini") and is dropped.
        merged.append(contentsOf: agents.filter {
            !defaultIDs.contains($0.id) && $0.id.hasPrefix("custom-")
        })
        result.agents = merged
        return result
    }
}
