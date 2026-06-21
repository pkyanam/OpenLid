import Foundation
import Observation
import SwiftUI

enum HoldState: Equatable {
    case off              // master toggle off
    case paused           // temporarily paused (30 min / 1 hour)
    case idle             // on, but nothing to hold awake for
    case holding          // agents working, wake lock active
    case willSleepSoon    // agents idle, in the grace countdown
    case blockedBattery   // would hold, but a battery guardrail prevents it

    var headerLabel: String {
        switch self {
        case .off: return "Off"
        case .paused: return "Paused"
        case .idle: return "On — idle"
        case .holding: return "Holding awake"
        case .willSleepSoon: return "Will sleep soon"
        case .blockedBattery: return "Paused — battery"
        }
    }

    var isActiveHold: Bool { self == .holding || self == .willSleepSoon }
}

@MainActor
@Observable
final class AppState {
    var config: AppConfig
    private(set) var battery: BatteryInfo = .unknown
    private(set) var agents: [AgentStatus] = []
    private(set) var state: HoldState = .idle
    private(set) var pausedUntil: Date?

    // Dependencies
    private let power = PowerManager()
    private let monitor = AgentMonitor()
    private let notifications = NotificationManager()
    private let hotKeys = HotKeyManager()

    // Internal session bookkeeping
    private var timer: Timer?
    private var engaged = false
    private var idleSince: Date?
    private var batteryNotified = false
    private var lastSavedConfig: AppConfig
    private let hookStaleTimeout: TimeInterval = 6 * 3600

    init() {
        let loaded = ConfigStore.load()
        config = loaded
        lastSavedConfig = loaded

        notifications.requestAuthorization()
        hotKeys.register { [weak self] in self?.toggleGlobal() }
        monitor.hookWatcher.startWatching { [weak self] in self?.tick() }
        startTimer()
        tick()
    }

    private func startTimer() {
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    // MARK: - Derived UI helpers

    var anyWorking: Bool { agents.contains { $0.isWorking } }
    var workingCount: Int { agents.filter { $0.isWorking }.count }

    var globalEnabledBinding: Binding<Bool> {
        Binding(get: { [weak self] in self?.config.globalEnabled ?? false },
                set: { [weak self] in self?.setGlobalEnabled($0) })
    }

    // MARK: - User actions

    func setGlobalEnabled(_ enabled: Bool) {
        config.globalEnabled = enabled
        pausedUntil = nil
        tick()
    }

    func toggleGlobal() { setGlobalEnabled(!config.globalEnabled) }

    func pause(minutes: Int) {
        pausedUntil = Date().addingTimeInterval(Double(minutes) * 60)
        tick()
    }

    func resume() {
        pausedUntil = nil
        tick()
    }

    // MARK: - Core evaluation loop

    func tick() {
        battery = BatteryMonitor.read()
        persistIfNeeded()
        agents = monitor.evaluate(agents: config.agents, staleAfter: hookStaleTimeout)

        // Expire pause.
        if let until = pausedUntil, Date() >= until { pausedUntil = nil }

        guard config.globalEnabled else {
            state = .off
            releaseHold()
            return
        }
        if let until = pausedUntil, Date() < until {
            state = .paused
            releaseHold()
            return
        }

        let blocked = batteryBlocksHold()

        if anyWorking {
            if blocked {
                state = .blockedBattery
                handleBatteryLimit()
                return
            }
            if !engaged { beginSession() }
            else { power.holdSystemAwake(reason: "Agents working") }
            idleSince = nil
            state = .holding
            return
        }

        // No agents working.
        if engaged {
            if idleSince == nil { idleSince = Date() }
            let elapsed = Date().timeIntervalSince(idleSince ?? Date())
            if elapsed >= Double(config.idleTimeoutSeconds) {
                finishSession()
                state = .idle
            } else {
                state = .willSleepSoon   // keep holding through the grace period
            }
        } else {
            state = .idle
        }
    }

    // MARK: - Session transitions

    private func beginSession() {
        engaged = true
        batteryNotified = false
        power.holdSystemAwake(reason: "Agents working")
        if config.displayOffWhileWorking { SleepController.displayOff() }
        notifications.notify(.engaged, notificationsEnabled: config.notificationsEnabled,
                             soundsEnabled: config.soundsEnabled)
    }

    private func finishSession() {
        power.releaseAll()
        engaged = false
        idleSince = nil
        notifications.notify(.finished, notificationsEnabled: config.notificationsEnabled,
                             soundsEnabled: config.soundsEnabled)
        if config.autoSleep {
            SleepController.sleepNow()
        } else if config.displayOffAfterFinishSeconds > 0 {
            let delay = Double(config.displayOffAfterFinishSeconds)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                SleepController.displayOff()
            }
        }
    }

    /// Release the wake lock without firing the "finished" chime (off / paused).
    private func releaseHold() {
        power.releaseAll()
        engaged = false
        idleSince = nil
    }

    private func handleBatteryLimit() {
        if !batteryNotified {
            batteryNotified = true
            notifications.notify(.batteryLimit, notificationsEnabled: config.notificationsEnabled,
                                 soundsEnabled: config.soundsEnabled)
            releaseHold()
            if config.autoSleep { SleepController.sleepNow() }
        } else {
            releaseHold()
        }
    }

    // MARK: - Guardrails

    private func batteryBlocksHold() -> Bool {
        if config.respectLowPowerMode && battery.isLowPowerMode { return true }
        guard battery.hasBattery, !battery.isOnAC else { return false }   // on AC / desktop: never blocked
        if config.onlyWhenPluggedIn { return true }
        if config.batteryCutoffEnabled && battery.percent <= config.batteryCutoffPercent { return true }
        return false
    }

    // MARK: - Persistence

    private func persistIfNeeded() {
        guard config != lastSavedConfig else { return }
        ConfigStore.save(config)
        lastSavedConfig = config
    }
}
