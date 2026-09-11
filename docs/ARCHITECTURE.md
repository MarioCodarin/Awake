# Architecture

Awake is a Swift package with three targets:

| Target | Role |
|---|---|
| `Awake` | SwiftUI `MenuBarExtra` app (`LSUIElement`, no Dock icon) |
| `AwakeCore` | Model, preferences, IOKit assertions, login item |
| `AwakeChecks` | Executable test suite |

## Disable sleep = `pmset disablesleep`

The switch is `SleepDisabled` 1 or 0:

- On → `pmset -a disablesleep 1` ( → Sleep greys out)
- Off → `pmset -a disablesleep 0` ( → Sleep works again)

The first change installs `/Library/PrivilegedHelperTools/com.mariocodarin.Awake.pmset` (password once). Later toggles call `sudo -n` on that helper with only `0` or `1`. The menu-bar app stays unprivileged.

IOKit assertions are extra idle protection while the flag is on:

| On | Assertion |
|---|---|
| Disable sleep | `PreventUserIdleSystemSleep` named `Awake` |
| Disable sleep | plus `PreventSystemSleep` named `Awake` when create succeeds |
| Keep display on | plus `PreventUserIdleDisplaySleep` named `Awake Display` |

Process exit drops assertions. `disablesleep` stays until the toggle sets 0 (or someone runs pmset).

## Data flow

```
AwakePopover  →  SleepModel  →  SystemSleepLockService (pmset 0/1)
                     │       →  SleepControlService (IOKit)
                     ├─ PreferencesStore (UserDefaults)
                     ├─ SleepClock (duration timer)
                     └─ LoginItemService (SMAppService)
```

The view never talks to IOKit.

## State rules

- Failed writes keep the last confirmed `keepAwake` value and set `errorMessage`.
- Concurrent writes while `isBusy` are ignored.
- `load()` runs from the menu-bar label at launch so a restored “on” state takes the assertion before the popover is opened.
- Duration timers are a single `Task` on `SleepModel`.

## Identity

- Bundle ID: `com.mariocodarin.Awake`
- Version: 1.0.3
- Copyright: Mario Codarin
