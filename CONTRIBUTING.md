# Contributing

## Setup

macOS 13+ and Swift 5.9+ (Xcode Command Line Tools are enough).

```sh
swift run AwakeChecks          # test suite, must stay green
./scripts/build-app.sh         # dist/Awake.app
./scripts/package-release.sh   # arm64 zip for a GitHub Release
```

## Layout

| Path | Module | Contents |
|---|---|---|
| `Sources/AwakeCore` | `AwakeCore` | `SleepModel`, models, service **protocols**. Foundation/Combine only. |
| `Sources/AwakePlatform` | `AwakePlatform` | Real services: IOKit assertions, `pmset` + helper, `SMAppService`, `UserDefaults`. |
| `Sources/AwakeTestSupport` | `AwakeTestSupport` | In-memory fakes, `ControllableSleepClock`. |
| `Sources/AwakeUI` | `AwakeUI` | `AwakePopover`, `Components/*`, `Theme`. |
| `Sources/Awake` | `Awake` | `@main` app, composition root (`AppContainer`), quit handling. |
| `Tests/AwakeCoreTests` | `AwakeChecks` | Executable check suite (not XCTest). |
| `Resources` | | `Info.plist`, app icon. |

**Dependency rule:** `AwakeCore` imports no system frameworks. `AwakeUI` depends only on `AwakeCore`, never on `AwakePlatform`. Only `AwakePlatform` links IOKit and ServiceManagement. Only `Awake` wires real services together.

## Adding a system capability

1. Add a protocol in `AwakeCore/Services`.
2. Implement it in `AwakePlatform`; add an in-memory fake in `AwakeTestSupport`.
3. Take it as an init parameter of `SleepModel` and extend `SleepModel(testing:)`.
4. Wire the real one in `AppContainer` (`Sources/Awake/AwakeApp.swift`).

Never call `Process`, IOKit or `SMAppService` from a view. Never block the main actor: run child processes through `ProcessRunner`.

## Tests

`swift run AwakeChecks` runs explicit scenarios. Add a `test…` method in an `extension AwakeChecks` file, then list it in `AwakeChecks.swift`; the PASS count is computed.

- Timer tests use `ControllableSleepClock`. Never sleep real minutes.
- The IOKit check filters `pmset -g assertions` to its own pid, so a running Awake.app does not affect it.

If you change how the helper, assertions or quit behavior work, also confirm on a Mac:

1. `./scripts/build-app.sh`, open `dist/Awake.app`, toggle Disable sleep on
2. `pmset -g | grep SleepDisabled` shows 1 and `pmset -g assertions` lists `Awake`
3. Quit from the popover
4. `SleepDisabled` is 0 and the assertions are gone

The administrator password dialog cannot be automated; test the first-install path by hand.

## Pull requests

- Keep the popover quiet and native. No extra windows, no Dock icon.
- Keep the helper minimal: it may only run `pmset -a disablesleep 0|1`.
- Do not add network access, accounts, or analytics.
- Match existing naming and error-copy style. Document public types with `///`.
