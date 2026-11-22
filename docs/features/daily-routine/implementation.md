# Daily routine: implementation

**Updated:** 2026-11-22 · [design](design.md)

Tasks are data in `game/scripts/days.gd` (`steps` are ids of props registered with `Apartment.use_point`). `Story._advance_task` takes the day's first unfinished task whose next step matches the used prop; the last step finishes it, may show a document, and Martin speaks. The task note (`Hud.show_tasks`) shows on waking, on completion and on the TASKS button. After 85 seconds with no progress Martin says a hint (`Days.HINT`).
