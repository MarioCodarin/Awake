# Architecture

Awake is a Swift package with three targets:

| Target | Role |
|---|---|
| `Awake` | SwiftUI `MenuBarExtra` app (`LSUIElement`, no Dock icon) |
| `AwakeCore` | Model, preferences, IOKit assertions, login item |
| `AwakeChecks` | Executable test suite |

## Data flow

```
AwakePopover  →  SleepModel  →  SleepControlService
                     │
                     ├─ PreferencesStore (UserDefaults)
                     ├─ SleepClock (duration timer)
                     └─ LoginItemService (SMAppService)
```

The view never talks to IOKit. `SleepModel` is the only object that decides when to create or release an assertion.

## SleepControlService

```swift
func read() async throws -> Bool
func set(keepAwake: Bool, preventDisplaySleep: Bool) async throws
```

- Production: `AssertionSleepControlService` via `IOPMAssertionCreateWithName`
- Tests: `DemoSleepControlService` and fakes

`preventDisplaySleep == true` uses `PreventUserIdleDisplaySleep`. `false` uses `PreventUserIdleSystemSleep` (display may sleep, Mac stays awake).

Turning keep-awake on while already on releases the previous assertion and creates a new one, so a display-mode change takes effect immediately.

## Assertion lifecycle

1. User turns Keep awake on → `SleepModel.setKeepAwake(true)` → `AssertionSleepControlService` creates an assertion named `Awake`.
2. Timer expiry, user toggle off, or `setKeepAwake(false)` → `IOPMAssertionRelease`.
3. Process exit or crash → macOS drops the assertion with the process. The Mac can sleep again. There is no leftover `disablesleep` flag.

## Why not pmset

`pmset -a disablesleep 1` needs administrator authorization and writes a persistent system setting. If the app dies, the Mac can remain unable to sleep until someone runs `pmset` again. A privileged helper would be required to do this without a sudo prompt.

IOKit assertions are the API Amphetamine, Caffeine, and KeepingYouAwake use. They are per-process, need no admin, and clean up on exit.

## State rules

- Failed writes keep the last confirmed `keepAwake` value and set `errorMessage`.
- Concurrent writes while `isBusy` are ignored.
- `load()` runs once per model instance. If preferences say keep-awake was on, it re-applies the assertion.
- Duration timers are a single `Task` on `SleepModel`. Changing duration while on cancels the previous task.

## Identity

- Bundle ID: `com.mariocodarin.Awake`
- Version: 1.0.0
- Copyright: Mario Codarin
