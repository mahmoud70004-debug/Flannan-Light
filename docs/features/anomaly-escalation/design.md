# Anomaly escalation

**Status:** designed · **Updated:** 2026-11-19 · [GDD](../../GDD.md)

Each `DayData` carries a tier (0–4) and a list of anomalies that alter the usual routine. The player is never told something is wrong; they notice. Martin's visit scripts are part of the same data, so his strangeness grows by edits to lines he has already said (pillars 3 and 5).

## Rules
1. Anomaly tiers: **0** normal; **1** a thing is slightly off (object moved, extra sound); **2** a thing contradicts the routine (stair count, log in own handwriting you did not write); **3** a thing contradicts reality (signal from a lighthouse not on the chart, clock stopped); **4** the world stops cooperating (tasks loop, Martin wrong).
2. An anomaly is a resource: trigger (time, room, task done), effect (set state, swap prop, play sound, edit log text), and "once" or "repeat".
3. Anomalies never harm the player and never block progress; at worst a task repeats once.
4. A tier never goes down between days; day 8 may be quieter than day 7 only by authored silence, not by lower tier.
5. Martin visits on days 1, 3, 5, 7, 9; each visit is a short branching script (max 3 player choices), and later visits reuse earlier lines with small edits.

## Numbers
| Day | Tier | Martin visit | Key beat [ASSUMPTION] |
|---|---|---|---|
| 1 | 0 | yes | Tutorial with Martin, he leaves |
| 2 | 0 | no | Alone; first real silence |
| 3 | 0–1 | yes | He notes something small |
| 4 | 1 | no | First moved object |
| 5 | 1–2 | yes | He repeats a phrase from day 3 |
| 6 | 2 | no | Stair count changes; unlisted lighthouse replies |
| 7 | 3 | yes | He arrives from the wrong side; no boat sound |
| 8 | 3–4 | no | Clock stops; tasks loop |
| 9 | 4 | yes | Climax conversation |
| 10 | 4 | no | Finale and ending choice |

## Edge cases
- Save/load restores anomaly states from flags, not from re-running triggers.
- Skipping a room that holds an anomaly is allowed; the anomaly is still logged in `GameState.flags`.

## Open questions
- [ASSUMPTION] Three endings, chosen by routine fidelity (how consistently the log was kept) and the day-10 choice.

## History
- 2026-11-19: designed.
