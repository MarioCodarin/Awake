# Contributing

## Setup

macOS 13+ and Swift 5.9+ (Xcode Command Line Tools are enough).

```sh
swift run AwakeChecks
./scripts/build-app.sh
```

## Layout

- `Sources/Awake` — SwiftUI menu-bar app
- `Sources/AwakeCore` — sleep model, IOKit assertions, preferences, login item
- `Tests/AwakeCoreTests` — `AwakeChecks` executable (not XCTest)
- `Resources` — `Info.plist` and app icon
- `scripts/build-app.sh` — release `.app` bundle

System integration belongs in `AwakeCore`, never in the view. Do not add `pmset`, `sudo`, or a privileged helper. Disable sleep always takes `PreventUserIdleSystemSleep`; `PreventSystemSleep` is a best-effort AC extra.

## Tests

`swift run AwakeChecks` must stay green. The suite is a `@main` executable with explicit scenarios. Add a new function, call it from `main()`, and keep the PASS line in sync.

Timer tests must use `ControllableSleepClock`. Do not sleep real minutes.

If you change how assertions are created, confirm on a Mac:

1. Build and open `dist/Awake.app`
2. Toggle Disable sleep on
3. `pmset -g assertions` lists `PreventUserIdleSystemSleep named: "Awake"`
4. Quit the app
5. The assertion is gone

## Pull requests

- Keep the popover quiet and native. No extra windows, no Dock icon.
- Do not add `pmset`, `sudo`, or a privileged helper.
- Do not add network, accounts, or analytics.
- Match existing naming and error-copy style.
