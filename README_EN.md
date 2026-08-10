# TeaKeeper

[中文](README.md)

TeaKeeper is a lightweight macOS menu bar utility that prevents idle system sleep. It can keep your Mac and background tasks running while the display turns off normally, or keep the display awake when needed.

> Current version: `0.1.2` (Build 5)
>
> Requirements: macOS 13.0 or later, Apple Silicon

## Features

- Prevents the Mac from entering idle system sleep.
- Allows the display to turn off according to macOS Energy settings by default while background tasks continue running.
- Optionally prevents display sleep and keeps the screen awake.
- Supports an infinite duration and presets from 5 minutes to 12 hours.
- Supports scheduled activation by time range and weekday.
- Can launch at login and enable prevent-sleep automatically when TeaKeeper starts.
- Can stop prevent-sleep automatically when battery level falls below 20%.
- Can toggle prevent-sleep with a left-click on the menu bar icon.
- Can optionally keep the host running with the lid closed; the built-in display is always allowed to sleep while the lid is closed.
- Automatically displays Simplified Chinese or English based on the preferred macOS language.

## Installation

1. Download `TeaKeeper.app.zip` from the [Releases](https://github.com/wf1woi/TeaKeeper/releases/latest) page.
2. Extract the archive and move `TeaKeeper.app` to the Applications folder.
3. On first launch, if macOS cannot verify the developer, Control-click or right-click TeaKeeper in Finder, choose **Open**, and confirm again.

The current build is not signed with a Developer ID certificate or notarized by Apple, so Gatekeeper will show a warning on first launch.

## Usage

TeaKeeper runs only in the menu bar and does not show a Dock icon.

1. Right-click the teacup icon in the menu bar to open the menu.
2. Select **Turn On Prevent Sleep** to keep the Mac running.
3. **Allow Screen Sleep (Mac Stays Awake)** is enabled by default. The display may turn black, but the Mac does not enter idle sleep, so downloads, builds, Codex, and other background tasks can continue.
4. Disable **Allow Screen Sleep** when you also want the display to remain on.
5. Use **Duration** or **Scheduled Prevent Sleep** to configure automatic activation and shutdown.
6. Select **Turn Off Prevent Sleep** or quit TeaKeeper to release the power assertions created by the app.

When **Left-click toggles prevent sleep** is enabled, left-clicking the menu bar icon toggles the state. Right-click always opens the menu.

## Sleep Behavior

- **A black display is not the same as system sleep.** When prevent-sleep is active and display sleep is allowed, the screen can turn off while the Mac and its background tasks keep running.
- **Display sleep is allowed by default.** TeaKeeper does not change the display timeout configured in macOS.
- **Closed-lid display safety takes priority.** TeaKeeper never forces the built-in display to stay lit while the lid is closed.
- **Keep Mac running with lid closed** is still subject to Mac model, power source, external-display setup, and macOS power policy. It does not replace Apple's officially supported closed-display requirements.

## Logs

Runtime diagnostics are stored at:

```text
~/Library/Logs/TeaKeeper/TeaKeeper.log
```

The log rotates to `TeaKeeper.old.log` at approximately 512 KB to help diagnose power assertion and wake-related issues.

## Build From Source

```bash
git clone https://github.com/wf1woi/TeaKeeper.git
cd TeaKeeper
./work/TeaKeeper/test.sh
./work/TeaKeeper/build.sh
```

The built app is written to `outputs/TeaKeeper.app`. The current build script targets Apple Silicon and applies an ad-hoc signature.
