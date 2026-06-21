import Foundation
import HotKey

/// Registers the global ⌥⌘L shortcut to toggle OpenLid on/off.
final class HotKeyManager {
    private var hotKey: HotKey?

    func register(handler: @escaping () -> Void) {
        // ⌥⌘L — fixed default for v0.1.
        let key = HotKey(key: .l, modifiers: [.command, .option])
        key.keyDownHandler = handler
        hotKey = key
    }

    func unregister() {
        hotKey = nil
    }
}
