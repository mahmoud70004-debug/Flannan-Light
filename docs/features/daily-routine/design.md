# Daily routine

**Status:** implemented · **Updated:** 2026-11-21 · [GDD](../../GDD.md)

Each day is a short list of ordinary tasks. Events interrupt them; the task list never stops mattering, even on the worst day.

## Rules
1. A day is a `DayData` resource: tasks, events (see [hallucination-director](../hallucination-director/design.md)), documents, phone calls.
2. Tasks are things Martin would really do: eat, wash, read mail, search for jobs on the laptop, call Jack, sleep. Each is "go to the place and use the object".
3. The day ends at sleep; the player may sleep once all required tasks are done. The task list shows as Martin's own sticky note (plain text).
4. Later days drop tasks Martin can no longer face (food, washing); fewer tasks is a story signal, not a punishment.

## Numbers [ASSUMPTION]
| Day | Required tasks | Length |
|---|---|---|
| 1 | 4 | 10–12 min |
| 2–6 | 3–4 | 8–10 min |
| 7–10 | 1–3 | 6–8 min |

## Open questions
- Hunger and tiredness meters? Not needed: the tasks carry it.
