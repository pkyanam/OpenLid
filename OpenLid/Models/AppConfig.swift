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
              detection: AgentDetection(hookID: "codex", processNames: ["codex"]),
              iconName: "agent.openai"),
        Agent(id: "opencode", name: "OpenCode",
              detection: AgentDetection(hookID: "opencode", processNames: ["opencode"]),
              iconName: "agent.opencode"),
        Agent(id: "gemini", name: "Gemini",
              detection: AgentDetection(hookID: "gemini", processNames: ["gemini"]),
              iconName: "agent.gemini"),
        Agent(id: "devin", name: "Devin",
              detection: AgentDetection(hookID: "devin", processNames: ["devin"]),
              iconName: "agent.devin"),
        Agent(id: "cursor", name: "Cursor",
              detection: AgentDetection(processNames: ["Cursor"]),
              iconName: "agent.cursor"),
    ]
}
