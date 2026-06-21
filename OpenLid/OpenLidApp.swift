import SwiftUI

@main
struct OpenLidApp: App {
    @State private var app = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(app: app)
        } label: {
            Image(systemName: menuBarSymbol)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(app: app)
        }
    }

    private var menuBarSymbol: String {
        switch app.state {
        case .off: return "powersleep"
        case .paused, .blockedBattery: return "pause.circle"
        case .holding, .willSleepSoon: return "bolt.fill"
        case .idle: return "laptopcomputer"
        }
    }
}
