import SwiftUI

/// The menu bar dropdown, mirroring the original holdmylid layout:
/// header + toggle, battery, agents, pause, footer.
struct MenuBarView: View {
    @Bindable var app: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            divider
            batterySection
            divider
            agentsSection
            divider
            pauseSection
            divider
            footer
        }
        .padding(.vertical, 12)
        .frame(width: 300)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 1) {
                Text("OpenLid").font(.system(size: 16, weight: .bold))
                Text(app.state.headerLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: app.globalEnabledBinding)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
    }

    // MARK: Battery

    private var batterySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Battery").font(.system(size: 15, weight: .semibold))
            ProgressView(value: Double(app.battery.percent), total: 100)
                .tint(batteryColor)
            HStack {
                Text(app.battery.hasBattery ? "\(app.battery.percent)% left" : "No battery")
                Spacer()
                Text(app.battery.powerLabel).foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
        .padding(.horizontal, 16)
    }

    private var batteryColor: Color {
        if app.battery.hasBattery && !app.battery.isOnAC
            && app.config.batteryCutoffEnabled
            && app.battery.percent <= app.config.batteryCutoffPercent {
            return .orange
        }
        return .green
    }

    // MARK: Agents

    private var agentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Agents").font(.system(size: 15, weight: .semibold))
                Spacer()
                Text("\(app.workingCount) working").foregroundStyle(.secondary).font(.subheadline)
            }
            if app.agents.isEmpty {
                Text("No agents enabled").foregroundStyle(.secondary).font(.subheadline)
            } else {
                ForEach(app.agents) { agent in
                    agentRow(agent)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func agentRow(_ agent: AgentStatus) -> some View {
        HStack(spacing: 8) {
            AgentIconView(iconName: agent.iconName, isWorking: agent.isWorking)
                .frame(width: 18)
            Text(agent.name)
                .foregroundStyle(agent.isWorking ? .primary : .secondary)
            Spacer()
            Text(agent.statusLabel)
                .foregroundStyle(.secondary)
                .font(.subheadline)
            Circle()
                .fill(Color.green)
                .frame(width: 7, height: 7)
                .opacity(agent.isWorking ? 1 : 0)
        }
    }

    // MARK: Pause

    private var pauseSection: some View {
        HStack {
            Text("Pause").font(.system(size: 15, weight: .semibold))
            Spacer()
            if app.pausedUntil != nil {
                Button("Resume") { app.resume() }
                    .buttonStyle(PillButtonStyle())
            } else {
                Button("30 min") { app.pause(minutes: 30) }
                    .buttonStyle(PillButtonStyle())
                Button("1 hour") { app.pause(minutes: 60) }
                    .buttonStyle(PillButtonStyle())
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: Footer

    private var footer: some View {
        VStack(alignment: .leading, spacing: 2) {
            SettingsLink {
                HStack {
                    Text("Settings…")
                    Spacer()
                    Text("⌘,").foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            MenuActionRow(title: "Quit OpenLid", shortcut: "⌘Q") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(.horizontal, 4)
    }

    private var divider: some View {
        Divider().padding(.vertical, 10).padding(.horizontal, 16)
    }
}
