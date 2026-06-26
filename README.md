# TeaKeeper

TeaKeeper is a small macOS menu bar utility that keeps your Mac awake.

## Features

- Menu bar tea icon with light/dark mode friendly rendering
- Prevent idle sleep
- Optional screen sleep allowance
- Optional system sleep assertion for lid-close scenarios
- Scheduled wake prevention by time range and weekday
- Duration presets
- Stop when battery is below 20%
- Optional left-click toggle
- Optional launch at login
- Chinese and English UI

## Usage

Download `TeaKeeper.app.zip` from the latest release:

<https://github.com/wf1woi/TeaKeeper/releases/latest>

Unzip it, open `TeaKeeper.app`, then use the tea icon in the macOS menu bar.

- Right-click the icon to open the menu.
- Enable `单击图标开启/关闭防休眠` / `Left-click toggles prevent sleep` if you want left-click toggling.
- Use `定时防休眠` / `Scheduled Prevent Sleep` to configure time and weekdays.

## Build

```bash
work/TeaKeeper/build.sh
```

The build output is written to:

```text
outputs/TeaKeeper.app
```

`outputs/` is ignored by git. Packaged builds are published through GitHub Releases.

## GitHub Token Permissions

For pushing this public repository with a classic personal access token:

- `public_repo`

If you want the repository to be private, use:

- `repo`

No `workflow`, package, or organization permissions are required.
