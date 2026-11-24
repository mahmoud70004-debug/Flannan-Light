# Daily routine

**Status:** designed · **Updated:** 2026-11-19 · [GDD](../../GDD.md)

Each day the player gets a short list of chores in a fixed order of places: clean the lamp room, check the lamp for faults, tidy the store, clean the bedroom, watch the sea, sleep. The chores are short, tactile and identical each day, so the player learns the island by muscle memory. That familiarity is what anomalies later betray (pillar 1).

## Rules
1. A day is a `DayData` resource listing its tasks, ship events, anomalies and whether Martin visits.
2. A task is one interactable object plus a short hold/tap action (wipe lens, trim wick, tighten fitting, stack crate, make bed). No task takes longer than the number in Numbers.
3. The task list is shown only in the keeper's log book (open from the Interact button on the desk), never as a HUD checklist.
4. Sleep is unlocked only when all required tasks of the day are done; optional tasks do not block sleep.
5. Sleeping ends the day, autosaves, applies the next `DayData`, and fades in the new morning.
6. The lamp must be lit at dusk; a lamp fault found by "check lamp" must be fixed before sleep (simple: one repair interaction).
7. Fixed route: store (ground) → bedroom → stairs → lamp room → gallery (outside, watch the sea).

## Numbers
| Name | Value | Unit | What to watch in playtests |
|---|---|---|---|
| Required tasks per day | 5–7 | tasks | Boredom vs. learnability |
| Max task duration | 6 | s | Phone thumb fatigue on hold actions |
| Day length (target) | 10–14 | min | Total playtime ≈ 2–2.5 h |
| Stair count (tower) | 62 | steps | Used by anomalies (count changes) |

## Edge cases
- Quitting mid-day: resume at the day's start (autosave only at sleep) [ASSUMPTION].
- Pause menu available at any time; tasks cannot be failed.
- Skipping a task: sleep stays locked and the log highlights it.

## Open questions
- [ASSUMPTION] Hold actions are acceptable on touch; tap-only fallback if not.

## History
- 2026-11-19: designed.
