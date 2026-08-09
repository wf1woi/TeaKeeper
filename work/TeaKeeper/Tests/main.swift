import Foundation
import IOKit.pwr_mgt

final class FakePowerAssertionBackend: PowerAssertionBackend {
    private(set) var activeIDs = Set<IOPMAssertionID>()
    private(set) var activeUserActivityIDs = Set<IOPMAssertionID>()
    private(set) var mutationActiveCounts: [Int] = []
    private(set) var createCount = 0
    private(set) var userActivityDeclareCount = 0
    private(set) var releasedIDs = Set<IOPMAssertionID>()
    var failingTypes = Set<String>()
    var failUserActivity = false
    private var nextID = IOPMAssertionID(1)

    func create(type: CFString, reason: CFString) -> (result: IOReturn, id: IOPMAssertionID) {
        createCount += 1
        if failingTypes.contains(type as String) {
            mutationActiveCounts.append(activeIDs.count)
            return (kIOReturnError, 0)
        }

        let id = nextID
        nextID += 1
        activeIDs.insert(id)
        mutationActiveCounts.append(activeIDs.count)
        return (kIOReturnSuccess, id)
    }

    func release(_ id: IOPMAssertionID) {
        let removedPowerAssertion = activeIDs.remove(id) != nil
        activeUserActivityIDs.remove(id)
        releasedIDs.insert(id)
        if removedPowerAssertion {
            mutationActiveCounts.append(activeIDs.count)
        }
    }

    func declareUserActivity(name: CFString, previousID: IOPMAssertionID) -> (result: IOReturn, id: IOPMAssertionID) {
        userActivityDeclareCount += 1
        guard !failUserActivity else { return (kIOReturnError, 0) }

        let id: IOPMAssertionID
        if previousID == 0 {
            id = nextID
            nextID += 1
        } else {
            id = previousID
        }
        activeUserActivityIDs.insert(id)
        return (kIOReturnSuccess, id)
    }

    func isValid(_ id: IOPMAssertionID) -> Bool {
        activeIDs.contains(id)
    }

    func resetMutationHistory() {
        mutationActiveCounts = []
    }
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        exit(1)
    }
}

func testReconfigurationKeepsOldAssertionUntilReplacementIsReady() throws {
    let backend = FakePowerAssertionBackend()
    let controller = PowerController(backend: backend)
    try controller.enable(allowDisplaySleep: true, lidAwake: false)
    backend.resetMutationHistory()

    try controller.enable(allowDisplaySleep: false, lidAwake: false)

    expect(backend.activeIDs.count == 2, "reconfigured controller should own idle and display assertions")
    expect(backend.mutationActiveCounts.min() ?? 0 >= 1, "reconfiguration must never leave zero active assertions")
}

func testFailedReconfigurationPreservesExistingAssertion() throws {
    let backend = FakePowerAssertionBackend()
    let controller = PowerController(backend: backend)
    try controller.enable(allowDisplaySleep: true, lidAwake: false)
    backend.resetMutationHistory()
    backend.failingTypes.insert(kIOPMAssertionTypePreventUserIdleDisplaySleep as String)

    do {
        try controller.enable(allowDisplaySleep: false, lidAwake: false)
        expect(false, "display assertion creation should fail")
    } catch {
        expect(backend.activeIDs.count == 1, "failed reconfiguration must preserve the previous idle assertion")
        expect(controller.assertionsAreValid(allowDisplaySleep: true, lidAwake: false), "previous configuration should remain valid")
        expect(backend.mutationActiveCounts.min() ?? 0 >= 1, "failed reconfiguration must not create an assertion gap")
    }
}

func testValidConfigurationDoesNotChurnAssertions() throws {
    let backend = FakePowerAssertionBackend()
    let controller = PowerController(backend: backend)
    try controller.enable(allowDisplaySleep: true, lidAwake: false)
    let createCount = backend.createCount
    backend.resetMutationHistory()

    try controller.enable(allowDisplaySleep: true, lidAwake: false)

    expect(backend.createCount == createCount, "valid assertions should be reused")
    expect(backend.mutationActiveCounts.isEmpty, "valid assertions should not be released and recreated")
}

func testUserActivityAssertionIsReusedAndReleased() throws {
    let backend = FakePowerAssertionBackend()
    let controller = PowerController(backend: backend)

    try controller.enable(allowDisplaySleep: false, lidAwake: false)
    expect(backend.activeUserActivityIDs.count == 1, "display-awake mode should create a user activity assertion")
    let activityID = backend.activeUserActivityIDs.first!

    controller.wakeDisplay(logSuccess: false)
    expect(backend.userActivityDeclareCount == 2, "display activity should be renewable")
    expect(backend.activeUserActivityIDs == [activityID], "display activity renewal should reuse the assertion ID")

    controller.disable()
    expect(backend.activeIDs.isEmpty, "disable should release power assertions")
    expect(backend.activeUserActivityIDs.isEmpty, "disable should release the user activity assertion")
    expect(backend.releasedIDs.contains(activityID), "the user activity assertion ID should be released")
}

func testUserActivityFailurePreservesPowerAssertions() throws {
    let backend = FakePowerAssertionBackend()
    backend.failUserActivity = true
    let controller = PowerController(backend: backend)

    try controller.enable(allowDisplaySleep: false, lidAwake: false)

    expect(controller.assertionsAreValid(allowDisplaySleep: false, lidAwake: false), "activity declaration failure must not discard working power assertions")
    expect(backend.activeUserActivityIDs.isEmpty, "failed activity declaration should not retain an invalid ID")
}

func testDisplaySleepPolicy() {
    expect(DisplaySleepPolicy.allowsDisplaySleep(userAllowsDisplaySleep: true, lidClosed: false), "the user preference should allow display sleep on an open Mac")
    expect(DisplaySleepPolicy.allowsDisplaySleep(userAllowsDisplaySleep: false, lidClosed: true), "a closed lid must always allow display sleep")
    expect(!DisplaySleepPolicy.allowsDisplaySleep(userAllowsDisplaySleep: false, lidClosed: false), "an open Mac should stay lit when display sleep is disabled")
    expect(!DisplaySleepPolicy.allowsDisplaySleep(userAllowsDisplaySleep: false, lidClosed: nil), "an unknown lid state should not disable display protection")
}

do {
    try testReconfigurationKeepsOldAssertionUntilReplacementIsReady()
    try testFailedReconfigurationPreservesExistingAssertion()
    try testValidConfigurationDoesNotChurnAssertions()
    try testUserActivityAssertionIsReusedAndReleased()
    try testUserActivityFailurePreservesPowerAssertions()
    testDisplaySleepPolicy()
    print("PowerController tests passed")
} catch {
    FileHandle.standardError.write(Data("FAIL: unexpected error: \(error)\n".utf8))
    exit(1)
}
