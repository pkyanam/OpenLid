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
              detection: .hook(agentID: "claude-code"), symbol: "sparkles"),
        Agent(id: "codex", name: "OpenAI Codex CLI",
              detection: .hook(agentID: "codex"), symbol: "chevron.left.forwardslash.chevron.right"),
        Agent(id: "opencode", name: "OpenCode",
              detection: .hook(agentID: "opencode"), symbol: "curlybraces"),
        Agent(id: "gemini", name: "Gemini",
              detection: .hook(agentID: "gemini"), symbol: "diamond"),
        Agent(id: "cursor", name: "Cursor",
              detection: .process(names: ["Cursor"]), symbol: "cursorarrow.rays"),
        Agent(id: "cline", name: "Cline",
              detection: .process(names: ["Code", "Code Helper (Plugin)"]), symbol: "terminal"),
    ]
}
