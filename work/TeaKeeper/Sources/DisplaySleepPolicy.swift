enum DisplaySleepPolicy {
    static func allowsDisplaySleep(userAllowsDisplaySleep: Bool, lidClosed: Bool?) -> Bool {
        userAllowsDisplaySleep || lidClosed == true
    }
}
