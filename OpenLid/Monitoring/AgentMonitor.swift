import Foundation

/// Combines hook-based and process-based detection into live `AgentStatus` values.
/// The hook signal (accurate) takes precedence; process detection is a coarse fallback.
final class AgentMonitor {
    let hookWatcher = HookWatcher()

    func evaluate(agents: [Agent], staleAfter: TimeInterval) -> [AgentStatus] {
        let enabled = agents.filter { $0.enabled }
        let hookCounts = hookWatcher.workingSessions(staleAfter: staleAfter)

        let needsProcessScan = enabled.contains { $0.detection.usesProcess }
        let runningNames = needsProcessScan ? ProcessWatcher.runningNames() : []

        return enabled.map { agent in
            let hookCount = agent.detection.hookID.map { hookCounts[$0] ?? 0 } ?? 0
            if hookCount > 0 {
                return AgentStatus(id: agent.id, name: agent.name, iconName: agent.iconName,
                                   isWorking: true, sessionCount: hookCount, detectedViaHook: true)
            }
            let processCount = agent.detection.usesProcess
                ? ProcessWatcher.matchCount(names: agent.detection.processNames, in: runningNames)
                : 0
            return AgentStatus(id: agent.id, name: agent.name, iconName: agent.iconName,
                               isWorking: processCount > 0, sessionCount: processCount,
                               detectedViaHook: false)
        }
    }
}
