import SwiftUI

struct SettingsView: View {
    @Bindable var app: AppState

    var body: some View {
        TabView {
            GeneralSettings(app: app)
                .tabItem { Label("General", systemImage: "gearshape") }
            BatterySettings(app: app)
                .tabItem { Label("Battery", systemImage: "battery.100") }
            DisplaySettings(app: app)
                .tabItem { Label("Display", systemImage: "display") }
            AgentsSettings(app: app)
                .tabItem { Label("Agents", systemImage: "cpu") }
            AboutSettings()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 460, height: 360)
    }
}

private struct GeneralSettings: View {
    @Bindable var app: AppState
    var body: some View {
        Form {
            Toggle("Enable OpenLid", isOn: app.globalEnabledBinding)
            Stepper("Idle timeout: \(app.config.idleTimeoutSeconds)s",
                    value: $app.config.idleTimeoutSeconds, in: 5...600, step: 5)
            Text("Wait this long after agents go idle before allowing sleep.")
                .font(.caption).foregroundStyle(.secondary)
            Toggle("Automatically sleep when agents finish", isOn: $app.config.autoSleep)
            Divider()
            Toggle("Show notifications", isOn: $app.config.notificationsEnabled)
            Toggle("Play sounds", isOn: $app.config.soundsEnabled)
            Divider()
            HStack {
                Text("Global shortcut")
                Spacer()
                Text("⌥⌘L").foregroundStyle(.secondary)
            }
            Text("Toggles OpenLid on or off from anywhere.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }
}

private struct BatterySettings: View {
    @Bindable var app: AppState
    var body: some View {
        Form {
            Toggle("Only hold awake when plugged in", isOn: $app.config.onlyWhenPluggedIn)
            Toggle("Stop holding below a battery threshold", isOn: $app.config.batteryCutoffEnabled)
            if app.config.batteryCutoffEnabled {
                HStack {
                    Slider(value: Binding(
                        get: { Double(app.config.batteryCutoffPercent) },
                        set: { app.config.batteryCutoffPercent = Int($0) }), in: 5...50, step: 5)
                    Text("\(app.config.batteryCutoffPercent)%").frame(width: 40, alignment: .trailing)
                }
            }
            Toggle("Respect Low Power Mode", isOn: $app.config.respectLowPowerMode)
            Text("These guardrails only apply on battery power.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }
}

private struct DisplaySettings: View {
    @Bindable var app: AppState
    var body: some View {
        Form {
            Toggle("Turn display off while agents are working", isOn: $app.config.displayOffWhileWorking)
            Stepper(app.config.displayOffAfterFinishSeconds == 0
                    ? "Turn display off after finish: Off"
                    : "Turn display off \(app.config.displayOffAfterFinishSeconds)s after finish",
                    value: $app.config.displayOffAfterFinishSeconds, in: 0...300, step: 5)
            Text("OpenLid uses public power assertions. Forcing the display off does not affect the wake lock keeping the system awake.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }
}

private struct AgentsSettings: View {
    @Bindable var app: AppState
    @State private var newName = ""
    @State private var newProcesses = ""

    var body: some View {
        Form {
            Section("Watched agents") {
                ForEach($app.config.agents) { $agent in
                    HStack {
                        AgentIconView(iconName: agent.iconName, isWorking: true).frame(width: 18)
                        VStack(alignment: .leading) {
                            Text(agent.name)
                            Text(detectionLabel(agent.detection))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $agent.enabled).labelsHidden()
                    }
                }
                .onDelete { app.config.agents.remove(atOffsets: $0) }
            }
            Section("Add a custom agent (process detection)") {
                TextField("Name", text: $newName)
                TextField("Process names (comma-separated)", text: $newProcesses)
                Button("Add agent") { addAgent() }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .formStyle(.grouped)
    }

    private func detectionLabel(_ detection: AgentDetection) -> String {
        switch (detection.usesHook, detection.usesProcess) {
        case (true, true): return "Lifecycle hook (process fallback)"
        case (true, false): return "Lifecycle hook"
        case (false, true): return "Process detection"
        case (false, false): return "Not configured"
        }
    }

    private func addAgent() {
        let names = newProcesses.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let trimmedName = newName.trimmingCharacters(in: .whitespaces)
        let id = "custom-" + UUID().uuidString.prefix(8)
        app.config.agents.append(
            Agent(id: String(id), name: trimmedName,
                  detection: AgentDetection(processNames: names.isEmpty ? [trimmedName] : names),
                  iconName: "agent.custom")
        )
        newName = ""
        newProcesses = ""
    }
}

private struct AboutSettings: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("OpenLid").font(.title2).bold()
                Text("Close the lid. Keep coding.").foregroundStyle(.secondary)
                Divider()
                Text("Limitations").font(.headline)
                Text("""
                OpenLid uses the same public power assertions as caffeinate and Amphetamine. \
                These prevent idle sleep, but macOS may still sleep in some lid-closed scenarios \
                — most notably on battery with no external display attached. OpenLid cannot \
                guarantee staying awake in every lid-closed situation. When in doubt, stay \
                plugged in or attach an external display.

                OpenLid is fully local: no network calls, no telemetry. It never requires sudo \
                and never changes your system power settings behind your back.
                """)
                .font(.callout)
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
