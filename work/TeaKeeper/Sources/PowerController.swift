import Foundation
import IOKit.pwr_mgt

protocol PowerAssertionBackend {
    func create(type: CFString, reason: CFString) -> (result: IOReturn, id: IOPMAssertionID)
    func declareUserActivity(name: CFString, previousID: IOPMAssertionID) -> (result: IOReturn, id: IOPMAssertionID)
    func release(_ id: IOPMAssertionID)
    func isValid(_ id: IOPMAssertionID) -> Bool
}

struct IOKitPowerAssertionBackend: PowerAssertionBackend {
    func create(type: CFString, reason: CFString) -> (result: IOReturn, id: IOPMAssertionID) {
        var id = IOPMAssertionID(0)
        let result = IOPMAssertionCreateWithName(
            type,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &id
        )
        return (result, id)
    }

    func declareUserActivity(name: CFString, previousID: IOPMAssertionID) -> (result: IOReturn, id: IOPMAssertionID) {
        var id = previousID
        let result = IOPMAssertionDeclareUserActivity(name, kIOPMUserActiveLocal, &id)
        return (result, id)
    }

    func release(_ id: IOPMAssertionID) {
        IOPMAssertionRelease(id)
    }

    func isValid(_ id: IOPMAssertionID) -> Bool {
        guard id != 0,
              let properties = IOPMAssertionCopyProperties(id) else {
            return false
        }
        properties.release()
        return true
    }
}

final class PowerController {
    private struct AssertionSet {
        var idle = IOPMAssertionID(0)
        var display = IOPMAssertionID(0)
        var system = IOPMAssertionID(0)
    }

    private struct Configuration: Equatable {
        let allowDisplaySleep: Bool
        let lidAwake: Bool
    }

    private let backend: PowerAssertionBackend
    private var idleAssertionID = IOPMAssertionID(0)
    private var displayAssertionID = IOPMAssertionID(0)
    private var systemAssertionID = IOPMAssertionID(0)
    private var userActivityAssertionID = IOPMAssertionID(0)
    private var configuration: Configuration?

    init(backend: PowerAssertionBackend = IOKitPowerAssertionBackend()) {
        self.backend = backend
    }

    var isEnabled: Bool {
        idleAssertionID != 0 || displayAssertionID != 0 || systemAssertionID != 0
    }

    func assertionsAreValid(allowDisplaySleep: Bool, lidAwake: Bool) -> Bool {
        guard backend.isValid(idleAssertionID) else { return false }

        if !allowDisplaySleep, !backend.isValid(displayAssertionID) {
            return false
        }

        if lidAwake, !backend.isValid(systemAssertionID) {
            return false
        }

        return true
    }

    func enable(allowDisplaySleep: Bool, lidAwake: Bool) throws {
        DebugLog.write("PowerController.enable allowDisplaySleep=\(allowDisplaySleep) lidAwake=\(lidAwake)")
        let requestedConfiguration = Configuration(
            allowDisplaySleep: allowDisplaySleep,
            lidAwake: lidAwake
        )

        if configuration == requestedConfiguration,
           assertionsAreValid(allowDisplaySleep: allowDisplaySleep, lidAwake: lidAwake) {
            DebugLog.write("PowerController.enable skipped; current assertions are valid")
            if !allowDisplaySleep {
                wakeDisplay()
            }
            return
        }

        let reason = "TeaKeeper Prevent Sleep" as CFString
        var replacements = AssertionSet()

        do {
            replacements.idle = try createAssertion(
                type: kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
                kind: L.text("assertion.idleSleep"),
                reason: reason
            )

            if !allowDisplaySleep {
                replacements.display = try createAssertion(
                    type: kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                    kind: L.text("assertion.displaySleep"),
                    reason: reason
                )
            }

            if lidAwake {
                replacements.system = try createAssertion(
                    type: kIOPMAssertionTypePreventSystemSleep as CFString,
                    kind: L.text("assertion.systemSleep"),
                    reason: reason
                )
            }
        } catch {
            release(replacements)
            throw error
        }

        let previous = AssertionSet(
            idle: idleAssertionID,
            display: displayAssertionID,
            system: systemAssertionID
        )
        idleAssertionID = replacements.idle
        displayAssertionID = replacements.display
        systemAssertionID = replacements.system
        configuration = requestedConfiguration
        release(previous)

        if allowDisplaySleep {
            releaseUserActivityAssertion()
        } else {
            wakeDisplay()
        }
    }

    func wakeDisplay(logSuccess: Bool = true) {
        let activity = backend.declareUserActivity(
            name: "TeaKeeper Keep Display Awake" as CFString,
            previousID: userActivityAssertionID
        )
        if logSuccess || activity.result != kIOReturnSuccess {
            DebugLog.write("user activity assertion result=\(activity.result) id=\(activity.id)")
        }
        if activity.result == kIOReturnSuccess {
            userActivityAssertionID = activity.id
        }
    }

    func disable() {
        let current = AssertionSet(
            idle: idleAssertionID,
            display: displayAssertionID,
            system: systemAssertionID
        )
        idleAssertionID = 0
        displayAssertionID = 0
        systemAssertionID = 0
        configuration = nil
        DebugLog.write("PowerController.disable idle=\(current.idle) display=\(current.display) system=\(current.system)")
        release(current)
        releaseUserActivityAssertion()
    }

    deinit {
        disable()
    }

    private func createAssertion(type: CFString, kind: String, reason: CFString) throws -> IOPMAssertionID {
        let creation = backend.create(type: type, reason: reason)
        DebugLog.write("\(kind) assertion result=\(creation.result) id=\(creation.id)")
        guard creation.result == kIOReturnSuccess else {
            throw PowerError.assertionFailed(kind, creation.result)
        }
        return creation.id
    }

    private func release(_ assertions: AssertionSet) {
        if assertions.idle != 0 {
            backend.release(assertions.idle)
        }
        if assertions.display != 0 {
            backend.release(assertions.display)
        }
        if assertions.system != 0 {
            backend.release(assertions.system)
        }
    }

    private func releaseUserActivityAssertion() {
        guard userActivityAssertionID != 0 else { return }
        backend.release(userActivityAssertionID)
        userActivityAssertionID = 0
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
