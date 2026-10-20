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

## Round 1 — after redesign

Changes: design tokens in `Theme` (4 pt spacing, radii, type, one amber accent, motion), hero card with
glyph + switch, one-click segmented duration, switch rows, error banner as a tinted card, footer reduced to
`Awake <version>` (links to GitHub) and `Quit ⌘Q` with hover/pressed states, wordmark header removed, new
vector icon with `scripts/make-icon.sh`. Reviewed light and dark for idle, active, timer, error and
first-run (helper missing) states.

| # | Criterion | Score | Notes |
|---|---|---|---|
| 1 | Launch experience | 8 | Nothing to flash; popover opens at its final size. Remaining: first paint shows the idle state for a few ms before `load()` resolves (model behavior, not changed). |
| 2 | App icon / logo | 8 | One bold symbol on a squircle, readable at 16 px, full `.icns`, SVG source and script in repo. Menu-bar glyph is an SF Symbol template (sun/moon). |
| 3 | Visual design | 8 | Consistent 4 pt rhythm, one accent, system type, no default-looking pickers or checkboxes. Slightly generous gap above the footer when the helper note shows. |
| 4 | Native feel | 8 | Native switches, segmented control and material; ⌘Q works. No Settings window or title bar by design (popover app). |
| 5 | Dark mode / accent | 8 | Semantic neutrals and opacity-based fills; checked in both modes. Brand amber is fixed rather than following the system accent. |
| 6 | Interaction & motion | 8 | 120–180 ms ease-out on state, error and hover; pressed state on footer buttons; Reduce Motion respected. |
| 7 | UX flow | 8 | Duration is one click instead of two; footer noise removed; plain-language errors and first-run note kept. |
| 8 | Accessibility | 8 | Spoken names for every control and duration segment, 24 pt minimum row height, errors not color-only. Not verified with VoiceOver on a live popover (see below). |

Honest limits: the live menu-bar popover could not be captured in this session, so screenshots come from
the harness hosting the same `AwakePopover` view (system material approximated with `NSVisualEffectView`).
The installed build was launched and its menu-bar item confirmed present.
