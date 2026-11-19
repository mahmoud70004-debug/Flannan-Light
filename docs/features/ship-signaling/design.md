# Ship signaling

**Status:** designed · **Updated:** 2026-11-19 · [GDD](../../GDD.md)

During some days a ship passes. The player spots it from the gallery, reads its bearing on the compass ring, and signals the far lighthouses with the shutter lamp so they know where it heads. It is the only "skill" moment in the game: small, procedural, and trusted. Later, the answers from the other lighthouses become the main carrier of dread (pillar 1, pillar 3).

## Rules
1. A ship event is data in `DayData`: spawn time, bearing path, ship silhouette, and whether it is real.
2. The ship is visible as a lit silhouette on the horizon; the player raises the binoculars (Interact on the telescope), which zooms the view.
3. The player taps one of 8 compass directions for the ship's heading, then holds the "send" button; the lamp shutter flashes a short pattern.
4. Each far lighthouse replies with a light pattern within the reply delay. A correct report gets a steady acknowledge; a wrong one gets a repeat request.
5. Replies come from lighthouses listed on the keeper's chart. Anomalous days may add a reply from a lighthouse that is not on the chart, a reply before the signal is sent, or no reply.
6. Missing or wrong reports never end the game; they only change log entries and later dialogue.

## Numbers
| Name | Value | Unit | What to watch in playtests |
|---|---|---|---|
| Far lighthouses on the chart | 3 | count | Enough to make a missing one noticeable |
| Compass choices | 8 | directions | Too hard on a small screen? |
| Signal duration | 4 | s | Tension vs. tedium |
| Reply delay | 3–6 | s | Waiting is the horror beat |
| Ships per day | 0–2 | count | Day 1 has exactly 1 |

## Edge cases
- Ship leaves view before the report: log notes "ship lost", no penalty.
- Player sleeps with a ship unreported: allowed; Martin mentions it at the next visit.

## Open questions
- [ASSUMPTION] A shutter lamp is a plausible 1900s signalling device (alternative: semaphore flags). Confirm period accuracy matters to the user.

## History
- 2026-11-19: designed.
