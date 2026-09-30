# Architecture

Awake is a Swift package with five library/app targets and one check suite.

```
Awake (app, composition root)
  ├── AwakeUI ───────────┐
  ├── AwakePlatform ─────┼──► AwakeCore   (protocols, models, SleepModel)
  └── AwakeCore          │         ▲
AwakeChecks ─────────────┴─────────┘  (also uses AwakeTestSupport → AwakeCore)
```

| Target | Role | Imports |
|---|---|---|
| `AwakeCore` | `SleepModel`, `AwakeDuration`, `AwakePreferences`, `SystemSleepLock` parsing, service protocols | Foundation, Combine |
| `AwakePlatform` | Real services (below) | IOKit, ServiceManagement, AwakeCore |
| `AwakeTestSupport` | In-memory fakes, `ControllableSleepClock`, `SleepModel(testing:)` | AwakeCore |
| `AwakeUI` | `AwakePopover`, `Components/*`, `Theme`, `AppInfo` | SwiftUI, AwakeCore |
| `Awake` | `@main`, `AppContainer` (wires real services), `AppDelegate` (restore sleep on quit) | all of the above |
| `AwakeChecks` | Executable test suite | AwakeCore, AwakePlatform, AwakeTestSupport |

`AwakeUI` never imports `AwakePlatform`, and `AwakeCore` never imports a system framework: the model can be tested with fakes and the view cannot reach IOKit or `Process`.

## Services

| Protocol (`AwakeCore/Services`) | Real implementation (`AwakePlatform`) |
|---|---|
| `SystemSleepLockService` | `PmsetSystemSleepLockService` (`pmset -g`, sudo helper, `HelperInstaller`) |
| `SleepControlService` | `AssertionSleepControlService` over `IOKitAssertionClient` |
| `LoginItemService` | `SMAppServiceLoginItemService` |
| `PreferencesStore` | `UserDefaultsPreferencesStore` |
| `SleepClock` | `RealSleepClock` |

## Disable sleep = `pmset disablesleep`

- On → `pmset -a disablesleep 1` ( → Sleep greys out)
- Off → `pmset -a disablesleep 0`

The first change installs `/Library/PrivilegedHelperTools/com.mariocodarin.Awake.pmset` plus a sudoers rule through one administrator prompt (`HelperInstaller`). Later changes run `sudo -n <helper> 0|1`, which never prompts. The menu-bar app stays unprivileged.

IOKit assertions add in-process protection while the flag is on:

| On | Assertion |
|---|---|
| Disable sleep | `PreventUserIdleSystemSleep` named `Awake` |
| Disable sleep | plus `PreventSystemSleep` named `Awake` when creation succeeds |
| Keep display on | plus `PreventUserIdleDisplaySleep` named `Awake Display` |

Process exit drops the assertions. The `disablesleep` flag is restored to 0 by `SleepModel.shutdown()`, called from `applicationShouldTerminate` (5 s watchdog so a stuck helper cannot block quitting). A force-kill skips this; the next launch reads the leftover flag and shows it as on.

## Data flow

```
AwakePopover ─► SleepModel ─► SystemSleepLockService  (pmset 0/1)
   (views)          │      ─► SleepControlService      (IOKit)
                    ├─ PreferencesStore   (UserDefaults)
                    ├─ SleepClock         (duration timer)
                    └─ LoginItemService   (SMAppService)
```

## State rules

- `keepAwake` mirrors the confirmed `pmset` flag. A failed write leaves it unchanged and sets `errorMessage`.
- Writes while `isBusy` are ignored. A timer expiry that arrives while busy is remembered and applied when the write ends.
- `load()` runs at launch (menu-bar label) and on each popover appearance. It re-reads `pmset` but **does not restart a running timer** and only rebuilds assertions if they disagree with the flag.
- The duration timer is one `Task`; it is armed on off→on or a duration change. `endDate` publishes when it fires.
- Timer expiry and quit never prompt for a password (`allowHelperInstall: false`); only a user toggle can install the helper.
- All child processes run off the main actor (`ProcessRunner`), so the UI stays responsive during `pmset` and the password prompt.

## Identity

- Bundle ID: `com.mariocodarin.Awake`
- Version: `CFBundleShortVersionString` in `Resources/Info.plist` (the UI reads it at runtime)
- Copyright: Mario Codarin
