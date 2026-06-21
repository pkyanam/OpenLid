import Foundation

/// Side-effecting system controls that don't require admin rights.
enum SleepController {
    /// Asks macOS to sleep via Apple Events. The first call may prompt the user to
    /// allow OpenLid to control "System Events" (Automation permission).
    static func sleepNow() {
        run("/usr/bin/osascript", ["-e", "tell application \"System Events\" to sleep"])
    }

    /// Turns the display off immediately. `pmset displaysleepnow` does not need sudo.
    static func displayOff() {
        run("/usr/bin/pmset", ["displaysleepnow"])
    }

    private static func run(_ launchPath: String, _ args: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = args
        do {
            try process.run()
        } catch {
            NSLog("OpenLid: failed to run \(launchPath): \(error)")
        }
    }
}
