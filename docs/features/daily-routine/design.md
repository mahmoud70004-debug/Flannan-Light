# Daily routine

**Status:** implemented · **Updated:** 2026-11-21 · [GDD](../../GDD.md)

Each day is a short list of ordinary tasks. Events interrupt them; the task list never stops mattering, even on the worst day.

## Rules
1. A day is a `DayData` resource: tasks, events (see [hallucination-director](../hallucination-director/design.md)), documents, phone calls.
2. Tasks are things Martin would really do: eat, wash, read mail, search for jobs on the laptop, call Jack, sleep. Each is "go to the place and use the object".
3. The day ends at sleep; the player may sleep once all required tasks are done. The task list shows as Martin's own sticky note (plain text).
4. Later days drop tasks Martin can no longer face (food, washing); fewer tasks is a story signal, not a punishment.

## Pacing (v0.5): one thing at a time
The first build poured tasks, events and scares onto the player in the first minutes. Now:
1. A day starts with a quiet stretch (40 s on day 1, 22 s after) to look around.
2. Martin then thinks aloud ("I have to eat something."), and after a beat an **OBJECTIVE** appears top left
   ("Go to the kitchen"). It follows the step ("Eat on the sofa") and says where to go.
3. Only the current task accepts steps. The TASKS list shows what is done and what he is on, never what is next.
4. When the task is done the objective goes and a quiet stretch follows (38 s on day 1, 24 s on day 9) before the next thought.
5. Scripted moments hang on progress (`after` a task, `when` a task becomes current), never on the clock, so they land in
   the quiet stretches. Random events start late (170 s on day 1), are at least 55 s apart (28 s by day 10), and are held
   back for 18 s after every new objective. Fear follows the share of tasks done, not time.
6. When the last task is done the remaining scripted moments are hurried (6 to 15 s apart) so the bed is never stuck;
   then "I should try to sleep." and the objective "Go to bed".

## Numbers [ASSUMPTION]
| Day | Required tasks | Length |
|---|---|---|
| 1 | 4 | 10–12 min |
| 2–6 | 3–4 | 8–10 min |
| 7–10 | 1–3 | 6–8 min |

## Open questions
- Hunger and tiredness meters? Not needed: the tasks carry it.
