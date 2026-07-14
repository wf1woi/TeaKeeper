import Foundation

enum PrefKey {
    static let enableAtLaunch = "enableAtLaunch"
    static let allowDisplaySleep = "allowDisplaySleep"
    static let stopOnLowBattery = "stopOnLowBattery"
    static let selectedDurationSeconds = "selectedDurationSeconds"
    static let scheduleEnabled = "scheduleEnabled"
    static let scheduleStartMinutes = "scheduleStartMinutes"
    static let scheduleEndMinutes = "scheduleEndMinutes"
    static let scheduleWeekdaysMask = "scheduleWeekdaysMask"
    static let lidAwake = "lidAwake"
    static let clickToggleEnabled = "clickToggleEnabled"
}

struct DurationOption: Equatable {
    let titleKey: String
    let seconds: TimeInterval?

    var title: String {
        L.text(titleKey)
    }

    var storedValue: Double {
        seconds ?? 0
    }

    static let all: [DurationOption] = [
        DurationOption(titleKey: "duration.infinite", seconds: nil),
        DurationOption(titleKey: "duration.5m", seconds: 5 * 60),
        DurationOption(titleKey: "duration.10m", seconds: 10 * 60),
        DurationOption(titleKey: "duration.15m", seconds: 15 * 60),
        DurationOption(titleKey: "duration.30m", seconds: 30 * 60),
        DurationOption(titleKey: "duration.45m", seconds: 45 * 60),
        DurationOption(titleKey: "duration.1h", seconds: 60 * 60),
        DurationOption(titleKey: "duration.2h", seconds: 2 * 60 * 60),
        DurationOption(titleKey: "duration.4h", seconds: 4 * 60 * 60),
        DurationOption(titleKey: "duration.8h", seconds: 8 * 60 * 60),
        DurationOption(titleKey: "duration.12h", seconds: 12 * 60 * 60)
    ]

    static func option(for storedValue: Double) -> DurationOption {
        all.first { $0.storedValue == storedValue } ?? all[0]
    }
}

extension UserDefaults {
    func registerTeaKeeperDefaults() {
        register(defaults: [
            PrefKey.enableAtLaunch: false,
            PrefKey.allowDisplaySleep: true,
            PrefKey.stopOnLowBattery: true,
            PrefKey.selectedDurationSeconds: 0,
            PrefKey.scheduleEnabled: false,
            PrefKey.scheduleStartMinutes: 9 * 60,
            PrefKey.scheduleEndMinutes: 18 * 60,
            PrefKey.scheduleWeekdaysMask: 0b1111111,
            PrefKey.lidAwake: false,
            PrefKey.clickToggleEnabled: false
        ])
    }
}

enum Weekday: Int, CaseIterable {
    case monday = 0
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday

    var bit: Int {
        1 << rawValue
    }

    var title: String {
        L.text("weekday.\(rawValue)")
    }

    static func currentBit(calendar: Calendar = .current, date: Date = Date()) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        let mondayBasedIndex = (weekday + 5) % 7
        return 1 << mondayBasedIndex
    }
}
