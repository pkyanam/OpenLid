import Foundation
import IOKit.ps

struct BatteryInfo: Equatable {
    var percent: Int          // 0...100
    var isOnAC: Bool          // plugged into power
    var isCharging: Bool
    var hasBattery: Bool      // false on desktop Macs
    var isLowPowerMode: Bool

    static let unknown = BatteryInfo(percent: 100, isOnAC: true, isCharging: false,
                                     hasBattery: false, isLowPowerMode: false)

    var powerLabel: String {
        if !hasBattery { return "on AC power" }
        if isCharging { return "charging" }
        return isOnAC ? "on AC power" : "on battery"
    }
}

enum BatteryMonitor {
    static func read() -> BatteryInfo {
        let lpm = ProcessInfo.processInfo.isLowPowerModeEnabled

        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef]
        else {
            return BatteryInfo(percent: 100, isOnAC: true, isCharging: false,
                               hasBattery: false, isLowPowerMode: lpm)
        }

        for source in sources {
            guard let desc = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue()
                    as? [String: Any] else { continue }

            let current = desc[kIOPSCurrentCapacityKey] as? Int ?? 0
            let maxCapacity = desc[kIOPSMaxCapacityKey] as? Int ?? 100
            let state = desc[kIOPSPowerSourceStateKey] as? String
            let isCharging = desc[kIOPSIsChargingKey] as? Bool ?? false
            let onAC = (state == kIOPSACPowerValue)
            let percent = maxCapacity > 0 ? Int((Double(current) / Double(maxCapacity) * 100).rounded()) : 0

            return BatteryInfo(percent: max(0, min(100, percent)), isOnAC: onAC,
                               isCharging: isCharging, hasBattery: true, isLowPowerMode: lpm)
        }

        // No power sources -> desktop Mac, effectively always on AC.
        return BatteryInfo(percent: 100, isOnAC: true, isCharging: false,
                           hasBattery: false, isLowPowerMode: lpm)
    }
}
