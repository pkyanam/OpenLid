import Foundation

/// Combines hook-based and process-based detection into live `AgentStatus` values.
final class AgentMonitor {
    let hookWatcher = HookWatcher()

    func evaluate(agents: [Agent], staleAfter: TimeInterval) -> [AgentStatus] {
        let enabled = agents.filter { $0.enabled }
        let hookCounts = hookWatcher.workingSessions(staleAfter: staleAfter)

        let needsProcessScan = enabled.contains { $0.detection.isHook == false }
        let tokens = needsProcessScan ? ProcessWatcher.runningTokens() : []

        return enabled.map { agent in
            switch agent.detection {
            case .hook(let agentID):
                let count = hookCounts[agentID] ?? 0
                return AgentStatus(id: agent.id, name: agent.name, symbol: agent.symbol,
                                   isWorking: count > 0, sessionCount: count)
            case .process(let names):
                let count = ProcessWatcher.matchCount(names: names, in: tokens)
                return AgentStatus(id: agent.id, name: agent.name, symbol: agent.symbol,
                                   isWorking: count > 0, sessionCount: count)
            }
        }
    }
}
