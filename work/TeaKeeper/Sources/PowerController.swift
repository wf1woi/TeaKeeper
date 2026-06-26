import Foundation
import IOKit.pwr_mgt

final class PowerController {
    private var idleAssertionID = IOPMAssertionID(0)
    private var displayAssertionID = IOPMAssertionID(0)
    private var systemAssertionID = IOPMAssertionID(0)

    var isEnabled: Bool {
        idleAssertionID != 0 || displayAssertionID != 0 || systemAssertionID != 0
    }

    func enable(allowDisplaySleep: Bool, lidAwake: Bool) throws {
        DebugLog.write("PowerController.enable allowDisplaySleep=\(allowDisplaySleep) lidAwake=\(lidAwake)")
        disable()

        let reason = "TeaKeeper Prevent Sleep" as CFString
        var idleID = IOPMAssertionID(0)
        let idleResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoIdleSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &idleID
        )

        DebugLog.write("idle assertion result=\(idleResult) id=\(idleID)")
        guard idleResult == kIOReturnSuccess else {
            throw PowerError.assertionFailed(L.text("assertion.idleSleep"), idleResult)
        }

        idleAssertionID = idleID

        if !allowDisplaySleep {
            var displayID = IOPMAssertionID(0)
            let displayResult = IOPMAssertionCreateWithName(
                kIOPMAssertionTypeNoDisplaySleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reason,
                &displayID
            )

            DebugLog.write("display assertion result=\(displayResult) id=\(displayID)")
            guard displayResult == kIOReturnSuccess else {
                disable()
                throw PowerError.assertionFailed(L.text("assertion.displaySleep"), displayResult)
            }

            displayAssertionID = displayID
        }

        guard lidAwake else { return }

        var systemID = IOPMAssertionID(0)
        let systemResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &systemID
        )

        DebugLog.write("system assertion result=\(systemResult) id=\(systemID)")
        guard systemResult == kIOReturnSuccess else {
            disable()
            throw PowerError.assertionFailed(L.text("assertion.systemSleep"), systemResult)
        }

        systemAssertionID = systemID
    }

    func disable() {
        if idleAssertionID != 0 {
            IOPMAssertionRelease(idleAssertionID)
            idleAssertionID = 0
        }

        if displayAssertionID != 0 {
            IOPMAssertionRelease(displayAssertionID)
            displayAssertionID = 0
        }

        if systemAssertionID != 0 {
            IOPMAssertionRelease(systemAssertionID)
            systemAssertionID = 0
        }
    }

    deinit {
        disable()
    }
}

enum PowerError: LocalizedError {
    case assertionFailed(String, IOReturn)

    var errorDescription: String? {
        switch self {
        case let .assertionFailed(kind, code):
            return L.format("alert.enableFailed.detail", kind, code)
        }
    }
}
