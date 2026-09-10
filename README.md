# Awake

<p align="center">
  <img src="docs/icon.png" width="128" height="128" alt="Awake app icon: a golden sun overlapping a silver moon on a night sky">
</p>

A tiny native macOS menu-bar app that keeps your Mac awake. One switch, quiet styling, no Dock icon, no admin prompt, no network.

Requires macOS 13 or later.

## Install

```sh
./scripts/build-app.sh
```

Then drag `dist/Awake.app` into `/Applications` and open it. A moon appears in the menu bar.

## Usage

Click the moon. Toggle **Keep awake**.

- **Duration** — Indefinite, 15 minutes, 30 minutes, 1 hour, or 2 hours. When a timer ends, Awake turns itself off.
- **Keep display on** — On (default) also prevents the display from sleeping. Off lets the display sleep while the Mac stays awake.
- **Launch at login** — Starts Awake when you log in. This is reliable after the app lives in `/Applications`.
- Last mode is remembered across launches.
- Quit with the power button in the popover, or Command-Q while the popover is open.

The menu-bar icon is a moon when idle and a sun while sleep is prevented.

## How it works

Awake uses Apple’s user-space power-management API (`IOPMAssertionCreateWithName`). It does **not** run `pmset`, request administrator access, or install a privileged helper.

When you turn Awake on, macOS records an assertion named `Awake`. When you turn it off, quit the app, or the process dies, the assertion is released and the Mac can sleep again.

You can confirm this while Awake is on:

```sh
pmset -g assertions
```

Look for `Awake` under `PreventUserIdleDisplaySleep` or `PreventUserIdleSystemSleep`.

## Privacy

Awake never leaves this Mac. No network, no accounts, no analytics, no data collection.

Preferences are stored in the app’s `UserDefaults` on this machine.

## Build and test

Requires Swift 5.9+ (Xcode Command Line Tools are sufficient).

```sh
swift run AwakeChecks
./scripts/build-app.sh
open dist/Awake.app
```

The build script produces a locally ad-hoc-signed app for the current Mac’s architecture. Developer ID signing and notarization are not included.

## Architecture

`AwakeApp` owns one `SleepModel` and presents `AwakePopover` through SwiftUI’s window-style `MenuBarExtra`.

`SleepModel` owns confirmed state, pending operations, recoverable errors, duration timers, and preferences. It talks to an injected `SleepControlService`. Failed writes keep the last confirmed state; concurrent writes are ignored while busy.

Production uses `AssertionSleepControlService` (IOKit). Tests use `DemoSleepControlService` and in-memory fakes.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the assertion lifecycle and why this is not `pmset`.

## License

MIT. Copyright © 2026 [Mario Codarin](https://github.com/MarioCodarin).
