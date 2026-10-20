# UI audit

Awake is a menu-bar popover app (SwiftUI `MenuBarExtra`, `LSUIElement`, no Dock icon, no document windows).
Criteria that assume a regular window (title bar, sidebar, Cmd+, Settings, state restoration, full screen)
are scored against what applies to a popover.

Screenshots are produced with a throw-away harness that hosts `AwakePopover` with in-memory fakes and
captures only its own window. They are not committed.

## Round 0 — baseline (v1.0.3)

| # | Criterion | Score | Main problems |
|---|---|---|---|
| 1 | Launch experience | 7 | No window to flash, instant. Popover first paints the "idle" state, then `load()` corrects it. |
| 2 | App icon / logo | 4 | Glossy, detailed sun+moon illustration: muddy at 32/16 px, two competing symbols, no vector source or generation script in the repo. |
| 3 | Visual design | 5 | Default-looking menu picker and checkboxes, five stacked sections, footer carries author, version, a blue default link and a helper note. Spacing is ad hoc (14/18/3/8). |
| 4 | Native feel | 6 | Wordmark "AWAKE" duplicates the menu-bar item; Quit is a tiny glyph; no overflow menu. |
| 5 | Dark mode / accent | 7 | Semantic colors throughout, but hardcoded `.green`/`.red` and no shared palette. |
| 6 | Interaction & motion | 5 | Only the main toggle animates; no hover or pressed states anywhere. |
| 7 | UX flow | 6 | Changing duration needs two clicks (open menu, choose). Footer text is noise once read. |
| 8 | Accessibility | 6 | Labels exist; Quit has a label but the power glyph is 11 pt; link and checkbox targets are small. |
