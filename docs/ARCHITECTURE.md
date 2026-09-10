# Architecture

Awake is a Swift package with three targets:

| Target | Role |
|---|---|
| `Awake` | SwiftUI `MenuBarExtra` app (`LSUIElement`, no Dock icon) |
| `AwakeCore` | Model, preferences, IOKit assertions, login item |
| `AwakeChecks` | Executable test suite |

## Why not `sudo pmset -a disablesleep 1`

That command writes a persistent system setting and needs administrator authorization. If you forget `disablesleep 0`, the Mac may not sleep until someone runs pmset again.

Awake holds IOKit assertions in-process instead:

| On | Assertion |
|---|---|
| Disable sleep | `PreventUserIdleSystemSleep` named `Awake` (always; works on battery) |
| Disable sleep | plus `PreventSystemSleep` named `Awake` when create succeeds (stronger on AC; often ignored on battery) |
| Keep display on | plus `PreventUserIdleDisplaySleep` named `Awake Display` |

New assertions are created before old ones are released, so a failed update cannot drop the previous hold. Failed releases keep those IDs so a later off/quit can retry. Process exit also drops them. There is no leftover `disablesleep` flag.

`PreventSystemSleep` is deprecated in the IOKit headers; `caffeinate -s` still uses it. Idle-system is Apple’s supported type and is what actually holds on battery.

## Data flow

```
AwakePopover  →  SleepModel  →  SleepControlService
                     │
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
- Version: 1.0.1
- Copyright: Mario Codarin
