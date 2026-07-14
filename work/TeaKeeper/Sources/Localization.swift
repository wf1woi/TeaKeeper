import Foundation

enum L {
    private static var useChinese: Bool {
        Locale.preferredLanguages.first?.lowercased().hasPrefix("zh") == true
    }

    static func text(_ key: String) -> String {
        if useChinese, let value = zh[key] {
            return value
        }
        return en[key] ?? key
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), arguments: arguments)
    }

    private static let en: [String: String] = [
        "duration.infinite": "Infinite",
        "duration.5m": "5 minutes",
        "duration.10m": "10 minutes",
        "duration.15m": "15 minutes",
        "duration.30m": "30 minutes",
        "duration.45m": "45 minutes",
        "duration.1h": "1 hour",
        "duration.2h": "2 hours",
        "duration.4h": "4 hours",
        "duration.8h": "8 hours",
        "duration.12h": "12 hours",
        "menu.section.start": "Start",
        "menu.section.general": "General",
        "menu.section.other": "Other",
        "menu.status.off": "Status: OFF",
        "menu.status.on.infinite": "Status: ON (%@) - Infinite",
        "menu.status.on.hours": "Status: ON (%@) - %dh %02dm left",
        "menu.status.on.minutes": "Status: ON (%@) - %dm %02ds left",
        "menu.status.on.seconds": "Status: ON (%@) - %ds left",
        "menu.status.screenAllowed": "screen may sleep",
        "menu.status.screenPrevented": "screen stays awake",
        "menu.turnOff": "Turn Off Prevent Sleep",
        "menu.turnOn": "Turn On Prevent Sleep",
        "menu.duration": "Duration",
        "menu.allowScreenSleep": "Allow Screen Sleep (Mac Stays Awake)",
        "menu.stopLowBattery": "Stop When Battery Is Below 20%",
        "menu.enableAtStartup": "Enable Prevent Sleep at Startup",
        "menu.openAtLogin": "Open at Login",
        "menu.scheduled": "Scheduled Prevent Sleep",
        "menu.scheduleEnabled": "Enable Timer",
        "menu.scheduleTimeRange": "%@ -- %@",
        "menu.lidAwake": "Keep Awake When Lid Is Closed",
        "menu.clickToggle": "Left-click toggles prevent sleep",
        "menu.quit": "Quit TeaKeeper",
        "tooltip.on": "TeaKeeper: Prevent Sleep On",
        "tooltip.off": "TeaKeeper: Prevent Sleep Off",
        "alert.enableFailed.title": "Could not enable prevent sleep.",
        "alert.enableFailed.detail": "Could not create %@ assertion. IOKit returned %d.",
        "assertion.idleSleep": "idle sleep",
        "assertion.displaySleep": "display sleep",
        "assertion.systemSleep": "system sleep",
        "weekday.0": "Mon",
        "weekday.1": "Tue",
        "weekday.2": "Wed",
        "weekday.3": "Thu",
        "weekday.4": "Fri",
        "weekday.5": "Sat",
        "weekday.6": "Sun",
        "schedule.status": "Status",
        "schedule.time": "Time",
        "schedule.timeHelp": "00:00 -- 00:00 means 24 hours."
    ]

    private static let zh: [String: String] = [
        "duration.infinite": "无限",
        "duration.5m": "5 分钟",
        "duration.10m": "10 分钟",
        "duration.15m": "15 分钟",
        "duration.30m": "30 分钟",
        "duration.45m": "45 分钟",
        "duration.1h": "1 小时",
        "duration.2h": "2 小时",
        "duration.4h": "4 小时",
        "duration.8h": "8 小时",
        "duration.12h": "12 小时",
        "menu.section.start": "启动",
        "menu.section.general": "一般",
        "menu.section.other": "其他",
        "menu.status.off": "状态：已关闭",
        "menu.status.on.infinite": "状态：已开启（%@）- 无限",
        "menu.status.on.hours": "状态：已开启（%@）- 剩余 %d 小时 %02d 分钟",
        "menu.status.on.minutes": "状态：已开启（%@）- 剩余 %d 分钟 %02d 秒",
        "menu.status.on.seconds": "状态：已开启（%@）- 剩余 %d 秒",
        "menu.status.screenAllowed": "屏幕可休眠",
        "menu.status.screenPrevented": "屏幕保持唤醒",
        "menu.turnOff": "关闭防休眠",
        "menu.turnOn": "开启防休眠",
        "menu.duration": "持续时间",
        "menu.allowScreenSleep": "允许屏幕休眠（主机保持唤醒）",
        "menu.stopLowBattery": "电量低于 20% 时停止",
        "menu.enableAtStartup": "启动时开启防休眠",
        "menu.openAtLogin": "开机自动启动",
        "menu.scheduled": "定时防休眠",
        "menu.scheduleEnabled": "定时开启",
        "menu.scheduleTimeRange": "%@ -- %@",
        "menu.lidAwake": "Mac 合上盖子不休眠",
        "menu.clickToggle": "单击图标开启/关闭防休眠",
        "menu.quit": "退出 TeaKeeper",
        "tooltip.on": "TeaKeeper：防休眠已开启",
        "tooltip.off": "TeaKeeper：防休眠已关闭",
        "alert.enableFailed.title": "无法开启防休眠。",
        "alert.enableFailed.detail": "无法创建 %@ 断言。IOKit 返回 %d。",
        "assertion.idleSleep": "系统休眠",
        "assertion.displaySleep": "屏幕休眠",
        "assertion.systemSleep": "系统睡眠",
        "weekday.0": "周一",
        "weekday.1": "周二",
        "weekday.2": "周三",
        "weekday.3": "周四",
        "weekday.4": "周五",
        "weekday.5": "周六",
        "weekday.6": "周日",
        "schedule.status": "状态",
        "schedule.time": "时间",
        "schedule.timeHelp": "00:00 -- 00:00 代表 24 小时。"
    ]
}
