import Foundation
import IOKit.pwr_mgt

/// Wraps IOKit power assertions — the same public mechanism used by `caffeinate`.
///
/// - System assertion (`PreventUserIdleSystemSleep`) keeps the Mac from idle-sleeping.
/// - Display assertion (`PreventUserIdleDisplaySleep`) keeps the screen on; we drop it
///   (and optionally force the display off) when we want a dark screen while staying awake.
final class PowerManager {
    private var systemAssertionID: IOPMAssertionID = IOPMAssertionID(0)
    private var displayAssertionID: IOPMAssertionID = IOPMAssertionID(0)

    private(set) var isHoldingSystem = false
    private(set) var isHoldingDisplay = false

    func holdSystemAwake(reason: String) {
        guard !isHoldingSystem else { return }
        var id = IOPMAssertionID(0)
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &id
        )
        if result == kIOReturnSuccess {
            systemAssertionID = id
            isHoldingSystem = true
        } else {
            NSLog("OpenLid: failed to create system sleep assertion (\(result))")
        }
    }

    func releaseSystemAwake() {
        guard isHoldingSystem else { return }
        IOPMAssertionRelease(systemAssertionID)
        systemAssertionID = IOPMAssertionID(0)
        isHoldingSystem = false
    }

    func holdDisplayAwake(reason: String) {
        guard !isHoldingDisplay else { return }
        var id = IOPMAssertionID(0)
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &id
        )
        if result == kIOReturnSuccess {
            displayAssertionID = id
            isHoldingDisplay = true
        } else {
            NSLog("OpenLid: failed to create display sleep assertion (\(result))")
        }
    }

    func releaseDisplayAwake() {
        guard isHoldingDisplay else { return }
        IOPMAssertionRelease(displayAssertionID)
        displayAssertionID = IOPMAssertionID(0)
        isHoldingDisplay = false
    }

    func releaseAll() {
        releaseSystemAwake()
        releaseDisplayAwake()
    }

    deinit { releaseAll() }
}
