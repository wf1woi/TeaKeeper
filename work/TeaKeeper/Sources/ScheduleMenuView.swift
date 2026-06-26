import AppKit

protocol ScheduleMenuViewDelegate: AnyObject {
    func scheduleMenuViewDidChange()
}

final class ScheduleMenuView: NSView {
    weak var delegate: ScheduleMenuViewDelegate?

    private let defaults = UserDefaults.standard
    private let enabledSwitch = NSSwitch()
    private let startPicker = NSDatePicker()
    private let endPicker = NSDatePicker()
    private var weekdayButtons: [NSButton] = []

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 340, height: 270))
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        build()
        reload()
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func build() {
        let statusTitle = header(L.text("schedule.status"))

        let enabledLabel = NSTextField(labelWithString: L.text("menu.scheduleEnabled"))
        enabledLabel.font = .systemFont(ofSize: 14, weight: .semibold)

        enabledSwitch.target = self
        enabledSwitch.action = #selector(toggleEnabled)
        let enabledRow = NSStackView(views: [enabledLabel, enabledSwitch])
        enabledRow.orientation = .horizontal
        enabledRow.alignment = .centerY
        enabledRow.distribution = .gravityAreas

        let timeTitle = header(L.text("schedule.time"))
        let timeHelp = helpLabel(L.text("schedule.timeHelp"))
        configureTimePicker(startPicker)
        configureTimePicker(endPicker)

        let dash = NSTextField(labelWithString: "--")
        dash.font = .systemFont(ofSize: 16, weight: .semibold)
        let timeRow = NSStackView(views: [startPicker, dash, endPicker])
        timeRow.orientation = .horizontal
        timeRow.alignment = .centerY
        timeRow.spacing = 14

        let dateTitle = header(L.text("schedule.date"))
        let weekdayGrid = NSGridView()
        weekdayGrid.rowSpacing = 10
        weekdayGrid.columnSpacing = 24
        weekdayGrid.xPlacement = .leading

        let rows = [
            [Weekday.monday, Weekday.thursday, Weekday.sunday],
            [Weekday.tuesday, Weekday.friday],
            [Weekday.wednesday, Weekday.saturday]
        ]

        for row in rows {
            var cells: [NSView] = row.map { weekday in
                let button = NSButton(checkboxWithTitle: weekday.title, target: self, action: #selector(toggleWeekday(_:)))
                button.tag = weekday.rawValue
                weekdayButtons.append(button)
                return button
            }
            while cells.count < 3 {
                cells.append(NSView())
            }
            weekdayGrid.addRow(with: cells)
        }

        let stack = NSStackView(views: [
            statusTitle,
            enabledRow,
            spacer(10),
            timeTitle,
            timeHelp,
            timeRow,
            spacer(12),
            dateTitle,
            weekdayGrid
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 9
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            startPicker.widthAnchor.constraint(equalToConstant: 82),
            endPicker.widthAnchor.constraint(equalToConstant: 82)
        ])
    }

    func reload() {
        enabledSwitch.state = defaults.bool(forKey: PrefKey.scheduleEnabled) ? .on : .off
        startPicker.dateValue = date(fromMinutes: defaults.integer(forKey: PrefKey.scheduleStartMinutes))
        endPicker.dateValue = date(fromMinutes: defaults.integer(forKey: PrefKey.scheduleEndMinutes))

        let mask = defaults.integer(forKey: PrefKey.scheduleWeekdaysMask)
        for button in weekdayButtons {
            button.state = (mask & (1 << button.tag)) != 0 ? .on : .off
        }
        updateEnabledState()
    }

    @objc private func toggleEnabled() {
        defaults.set(enabledSwitch.state == .on, forKey: PrefKey.scheduleEnabled)
        updateEnabledState()
        delegate?.scheduleMenuViewDidChange()
    }

    @objc private func timeChanged(_ sender: NSDatePicker) {
        defaults.set(minutes(from: startPicker.dateValue), forKey: PrefKey.scheduleStartMinutes)
        defaults.set(minutes(from: endPicker.dateValue), forKey: PrefKey.scheduleEndMinutes)
        delegate?.scheduleMenuViewDidChange()
    }

    @objc private func toggleWeekday(_ sender: NSButton) {
        var mask = defaults.integer(forKey: PrefKey.scheduleWeekdaysMask)
        if sender.state == .on {
            mask |= 1 << sender.tag
        } else {
            mask &= ~(1 << sender.tag)
        }
        defaults.set(mask, forKey: PrefKey.scheduleWeekdaysMask)
        delegate?.scheduleMenuViewDidChange()
    }

    private func configureTimePicker(_ picker: NSDatePicker) {
        picker.datePickerStyle = .textFieldAndStepper
        picker.datePickerElements = [.hourMinute]
        picker.target = self
        picker.action = #selector(timeChanged(_:))
    }

    private func updateEnabledState() {
        let enabled = enabledSwitch.state == .on
        startPicker.isEnabled = enabled
        endPicker.isEnabled = enabled
        weekdayButtons.forEach { $0.isEnabled = enabled }
    }

    private func header(_ title: String) -> NSTextField {
        let label = NSTextField(labelWithString: title)
        label.textColor = .tertiaryLabelColor
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        return label
    }

    private func helpLabel(_ title: String) -> NSTextField {
        let label = NSTextField(labelWithString: title)
        label.textColor = .tertiaryLabelColor
        label.font = .systemFont(ofSize: 12)
        return label
    }

    private func spacer(_ height: CGFloat) -> NSView {
        let view = NSView()
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }

    private func date(fromMinutes minutes: Int) -> Date {
        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60
        return Calendar.current.date(from: components) ?? Date()
    }

    private func minutes(from date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}
