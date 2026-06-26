import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, ScheduleMenuViewDelegate {
    private let defaults = UserDefaults.standard
    private let powerController = PowerController()
    private var statusItem: NSStatusItem!
    private var menu = NSMenu()
    private var tickTimer: Timer?
    private var endDate: Date?
    private var enabledBySchedule = false
    private var scheduleMenuView: ScheduleMenuView?

    func applicationDidFinishLaunching(_ notification: Notification) {
        defaults.registerTeaKeeperDefaults()
        DebugLog.write("didFinishLaunching enableAtLaunch=\(defaults.bool(forKey: PrefKey.enableAtLaunch)) allowDisplaySleep=\(defaults.bool(forKey: PrefKey.allowDisplaySleep))")
        NSApp.setActivationPolicy(.accessory)
        createStatusItem()
        rebuildMenu()
        startTimer()

        if defaults.bool(forKey: PrefKey.enableAtLaunch) {
            setAwake(true, source: "launch")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        powerController.disable()
    }

    private func createStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem.button else { return }
        button.action = #selector(statusItemClicked(_:))
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        updateStatusIcon()
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            statusItem.menu = menu
            sender.performClick(nil)
            statusItem.menu = nil
        } else if defaults.bool(forKey: PrefKey.clickToggleEnabled) {
            setAwake(!powerController.isEnabled, source: "manual")
        }
    }

    private func rebuildMenu() {
        menu = NSMenu()
        menu.autoenablesItems = false

        menu.addItem(sectionHeader(L.text("menu.section.start")))
        menu.addItem(openAtLoginMenuItem())
        menu.addItem(checkboxMenuItem(
            title: L.text("menu.enableAtStartup"),
            key: PrefKey.enableAtLaunch,
            action: #selector(togglePreference(_:))
        ))
        menu.addItem(scheduleMenuItem())
        menu.addItem(NSMenuItem.separator())

        menu.addItem(sectionHeader(L.text("menu.section.general")))
        menu.addItem(durationMenuItem())
        menu.addItem(checkboxMenuItem(
            title: L.text("menu.allowScreenSleep"),
            key: PrefKey.allowDisplaySleep,
            action: #selector(togglePreference(_:))
        ))
        menu.addItem(NSMenuItem.separator())

        menu.addItem(sectionHeader(L.text("menu.section.other")))
        menu.addItem(checkboxMenuItem(
            title: L.text("menu.lidAwake"),
            key: PrefKey.lidAwake,
            action: #selector(togglePreference(_:))
        ))
        menu.addItem(checkboxMenuItem(
            title: L.text("menu.stopLowBattery"),
            key: PrefKey.stopOnLowBattery,
            action: #selector(togglePreference(_:))
        ))
        menu.addItem(checkboxMenuItem(
            title: L.text("menu.clickToggle"),
            key: PrefKey.clickToggleEnabled,
            action: #selector(togglePreference(_:))
        ))

        menu.addItem(NSMenuItem.separator())
        let quit = NSMenuItem(title: L.text("menu.quit"), action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    private func sectionHeader(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        let attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .foregroundColor: NSColor.tertiaryLabelColor,
                .font: NSFont.systemFont(ofSize: 12, weight: .semibold)
            ]
        )
        item.attributedTitle = attributedTitle
        return item
    }

    private func openAtLoginMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: L.text("menu.openAtLogin"), action: #selector(toggleOpenAtLogin), keyEquivalent: "")
        item.target = self
        item.state = LaunchAtLoginController.isEnabled() ? .on : .off
        return item
    }

    private func scheduleMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: L.text("menu.scheduled"), action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        submenu.autoenablesItems = false

        let view = ScheduleMenuView()
        view.delegate = self
        scheduleMenuView = view

        let viewItem = NSMenuItem()
        viewItem.view = view
        submenu.addItem(viewItem)

        item.submenu = submenu
        return item
    }

    private func durationMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: L.text("menu.duration"), action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        let current = DurationOption.option(for: defaults.double(forKey: PrefKey.selectedDurationSeconds))

        for option in DurationOption.all {
            if option.titleKey == "duration.1h" {
                submenu.addItem(NSMenuItem.separator())
            }
            let durationItem = NSMenuItem(title: option.title, action: #selector(selectDuration(_:)), keyEquivalent: "")
            durationItem.target = self
            durationItem.representedObject = option.storedValue
            durationItem.state = option == current ? .on : .off
            submenu.addItem(durationItem)
        }

        item.submenu = submenu
        return item
    }

    private func checkboxMenuItem(title: String, key: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.representedObject = key
        item.state = defaults.bool(forKey: key) ? .on : .off
        return item
    }

    private func scheduleRangeTitle() -> String {
        let start = timeString(fromMinutes: defaults.integer(forKey: PrefKey.scheduleStartMinutes))
        let end = timeString(fromMinutes: defaults.integer(forKey: PrefKey.scheduleEndMinutes))
        return L.format("menu.scheduleTimeRange", start, end)
    }

    private func timeString(fromMinutes minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }

    @objc private func toggleAwake() {
        setAwake(!powerController.isEnabled, source: "manual")
    }

    @objc private func selectDuration(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? Double else { return }
        defaults.set(value, forKey: PrefKey.selectedDurationSeconds)
        if powerController.isEnabled {
            applySelectedDuration()
        }
        rebuildMenu()
    }

    @objc private func toggleOpenAtLogin() {
        do {
            try LaunchAtLoginController.setEnabled(!LaunchAtLoginController.isEnabled())
        } catch {
            showAlert(message: L.text("alert.enableFailed.title"), detail: error.localizedDescription)
        }
        rebuildMenu()
    }

    @objc private func togglePreference(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String else { return }
        defaults.set(!defaults.bool(forKey: key), forKey: key)

        if key == PrefKey.allowDisplaySleep, powerController.isEnabled {
            setAwake(true, source: "preference")
        }

        if key == PrefKey.lidAwake, powerController.isEnabled {
            setAwake(true, source: "preference")
        }

        if key == PrefKey.scheduleEnabled {
            checkSchedule()
        }

        rebuildMenu()
    }

    func scheduleMenuViewDidChange() {
        checkSchedule()
        rebuildMenu()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func setAwake(_ enabled: Bool, source: String) {
        DebugLog.write("setAwake enabled=\(enabled) source=\(source)")
        if enabled {
            do {
                try powerController.enable(
                    allowDisplaySleep: defaults.bool(forKey: PrefKey.allowDisplaySleep),
                    lidAwake: defaults.bool(forKey: PrefKey.lidAwake)
                )
                if source != "schedule" {
                    enabledBySchedule = false
                }
                if source == "schedule" {
                    endDate = nil
                } else {
                    applySelectedDuration()
                }
            } catch {
                DebugLog.write("setAwake error=\(error.localizedDescription)")
                showAlert(message: L.text("alert.enableFailed.title"), detail: error.localizedDescription)
            }
        } else {
            powerController.disable()
            endDate = nil
            enabledBySchedule = false
        }

        updateStatusIcon()
        rebuildMenu()
    }

    private func applySelectedDuration() {
        let option = DurationOption.option(for: defaults.double(forKey: PrefKey.selectedDurationSeconds))
        if let seconds = option.seconds {
            endDate = Date().addingTimeInterval(seconds)
        } else {
            endDate = nil
        }
    }

    private func startTimer() {
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        if let endDate, Date() >= endDate {
            setAwake(false, source: "duration")
            return
        }

        if defaults.bool(forKey: PrefKey.stopOnLowBattery),
           powerController.isEnabled,
           let battery = BatteryMonitor.currentBatteryInfo(),
           battery.isOnBatteryPower,
           battery.percent < 20 {
            setAwake(false, source: "battery")
            return
        }

        checkSchedule()
        updateStatusIcon()
    }

    private func checkSchedule() {
        guard defaults.bool(forKey: PrefKey.scheduleEnabled) else { return }

        let nowDate = Date()
        let weekdayMask = defaults.integer(forKey: PrefKey.scheduleWeekdaysMask)
        guard (weekdayMask & Weekday.currentBit(date: nowDate)) != 0 else {
            if enabledBySchedule {
                setAwake(false, source: "schedule")
            }
            return
        }

        let now = Calendar.current.dateComponents([.hour, .minute], from: nowDate)
        let currentMinutes = (now.hour ?? 0) * 60 + (now.minute ?? 0)
        let start = defaults.integer(forKey: PrefKey.scheduleStartMinutes)
        let end = defaults.integer(forKey: PrefKey.scheduleEndMinutes)
        let withinSchedule: Bool

        if start == end {
            withinSchedule = true
        } else if start < end {
            withinSchedule = currentMinutes >= start && currentMinutes < end
        } else {
            withinSchedule = currentMinutes >= start || currentMinutes < end
        }

        if withinSchedule, !powerController.isEnabled {
            enabledBySchedule = true
            setAwake(true, source: "schedule")
        } else if !withinSchedule, enabledBySchedule {
            setAwake(false, source: "schedule")
        }
    }

    private func statusTitle() -> String {
        guard powerController.isEnabled else {
            return L.text("menu.status.off")
        }

        if let endDate {
            let remaining = max(0, Int(endDate.timeIntervalSinceNow))
            let hours = remaining / 3600
            let minutes = (remaining % 3600) / 60
            let seconds = remaining % 60
            if hours > 0 {
                return L.format("menu.status.on.hours", hours, minutes)
            }
            if minutes > 0 {
                return L.format("menu.status.on.minutes", minutes, seconds)
            }
            return L.format("menu.status.on.seconds", seconds)
        }

        return L.text("menu.status.on.infinite")
    }

    private func updateStatusIcon() {
        guard let button = statusItem?.button else { return }
        button.image = statusImage(filled: powerController.isEnabled)
        button.toolTip = powerController.isEnabled ? L.text("tooltip.on") : L.text("tooltip.off")
    }

    private func statusImage(filled: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.lockFocus()

        let stroke = NSColor.black
        stroke.setStroke()
        stroke.setFill()

        let steamLeft = NSBezierPath()
        steamLeft.move(to: NSPoint(x: 6.2, y: 15.2))
        steamLeft.curve(
            to: NSPoint(x: 5.9, y: 11.8),
            controlPoint1: NSPoint(x: 4.7, y: 14.3),
            controlPoint2: NSPoint(x: 7.4, y: 13.0)
        )
        steamLeft.lineWidth = 1.25
        steamLeft.lineCapStyle = .round
        steamLeft.stroke()

        let steamRight = NSBezierPath()
        steamRight.move(to: NSPoint(x: 10.4, y: 15.8))
        steamRight.curve(
            to: NSPoint(x: 10.2, y: 11.7),
            controlPoint1: NSPoint(x: 12.0, y: 14.8),
            controlPoint2: NSPoint(x: 8.7, y: 13.0)
        )
        steamRight.lineWidth = 1.25
        steamRight.lineCapStyle = .round
        steamRight.stroke()

        let leaf = NSBezierPath()
        leaf.move(to: NSPoint(x: 12.0, y: 15.0))
        leaf.curve(
            to: NSPoint(x: 15.6, y: 14.0),
            controlPoint1: NSPoint(x: 13.7, y: 17.0),
            controlPoint2: NSPoint(x: 15.5, y: 16.0)
        )
        leaf.curve(
            to: NSPoint(x: 12.0, y: 15.0),
            controlPoint1: NSPoint(x: 14.0, y: 13.5),
            controlPoint2: NSPoint(x: 12.8, y: 13.8)
        )
        leaf.lineWidth = 1.1
        if filled {
            leaf.fill()
        } else {
            leaf.stroke()
        }

        let cup = NSBezierPath()
        cup.move(to: NSPoint(x: 3.2, y: 10.1))
        cup.line(to: NSPoint(x: 12.1, y: 10.1))
        cup.curve(
            to: NSPoint(x: 10.4, y: 4.8),
            controlPoint1: NSPoint(x: 12.0, y: 7.4),
            controlPoint2: NSPoint(x: 11.6, y: 5.7)
        )
        cup.curve(
            to: NSPoint(x: 4.8, y: 4.8),
            controlPoint1: NSPoint(x: 8.9, y: 4.1),
            controlPoint2: NSPoint(x: 6.3, y: 4.1)
        )
        cup.curve(
            to: NSPoint(x: 3.2, y: 10.1),
            controlPoint1: NSPoint(x: 3.7, y: 5.7),
            controlPoint2: NSPoint(x: 3.3, y: 7.4)
        )
        cup.close()
        cup.lineWidth = 1.35
        if filled {
            cup.fill()
        } else {
            cup.stroke()
        }

        let handle = NSBezierPath()
        handle.move(to: NSPoint(x: 12.0, y: 9.2))
        handle.curve(
            to: NSPoint(x: 15.6, y: 7.5),
            controlPoint1: NSPoint(x: 14.6, y: 9.9),
            controlPoint2: NSPoint(x: 16.0, y: 9.0)
        )
        handle.curve(
            to: NSPoint(x: 12.3, y: 6.2),
            controlPoint1: NSPoint(x: 15.2, y: 5.9),
            controlPoint2: NSPoint(x: 13.8, y: 5.5)
        )
        handle.lineWidth = 1.35
        handle.lineCapStyle = .round
        handle.stroke()

        let saucer = NSBezierPath()
        saucer.move(to: NSPoint(x: 3.2, y: 3.6))
        saucer.curve(
            to: NSPoint(x: 12.9, y: 3.6),
            controlPoint1: NSPoint(x: 5.7, y: 2.6),
            controlPoint2: NSPoint(x: 10.5, y: 2.6)
        )
        saucer.lineWidth = 1.25
        saucer.lineCapStyle = .round
        saucer.stroke()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }

    private func showAlert(message: String, detail: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = detail
        alert.alertStyle = .warning
        alert.runModal()
    }
}
