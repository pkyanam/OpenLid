import Foundation
import UserNotifications
import AppKit

/// Banner notifications + bundled (system) chimes for key lifecycle moments.
enum OpenLidEvent {
    case engaged          // started holding the Mac awake
    case finished         // agents idle past the timeout
    case batteryLimit     // battery guardrail tripped

    var title: String {
        switch self {
        case .engaged: return "OpenLid engaged"
        case .finished: return "Agents finished"
        case .batteryLimit: return "Battery limit reached"
        }
    }

    var body: String {
        switch self {
        case .engaged: return "Holding your Mac awake while agents work."
        case .finished: return "Released the wake lock — your Mac can sleep now."
        case .batteryLimit: return "Battery is low. Releasing the wake lock."
        }
    }

    /// Names of built-in macOS system sounds (NSSound).
    var systemSoundName: String {
        switch self {
        case .engaged: return "Submarine"
        case .finished: return "Glass"
        case .batteryLimit: return "Funk"
        }
    }
}

final class NotificationManager {
    private var authorized = false

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            self?.authorized = granted
        }
    }

    func notify(_ event: OpenLidEvent, notificationsEnabled: Bool, soundsEnabled: Bool) {
        if soundsEnabled {
            NSSound(named: NSSound.Name(event.systemSoundName))?.play()
        }
        guard notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = event.body
        content.sound = nil   // we play the chime ourselves for distinct sounds

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
