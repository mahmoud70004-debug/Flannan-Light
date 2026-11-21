# No One Home — Game Design Document

**Version:** 0.1 · **Updated:** 2026-11-21 · [Features](#feature-index) · [Decisions](#decisions) · [Change log](#change-log)

> Replaces *Flannan Light* (lighthouse island), which is kept on branch `archive/flannan-light-v1`. The technical pipeline is unchanged; story, setting, look and name are new. "No One Home" is a working title (one constant in `scripts/title.gd`).

## Summary
Martin is in his thirties. He was a respected employee until he was fired for "misconduct and psychological problems"; he does not understand the second phrase. His parents died years ago, his only relative is his brother Jack, who lives in another state with a family of his own. Martin sits alone in a small, messy, depressing flat, and over **ten days** he becomes sure that someone, or something, is in the flat with him. He tries to hide, avoid it and find an explanation, while living an ordinary day (eating, applying for jobs, sleeping). Slowly the player understands there is no intruder: Martin has been ill all along. The game ends with him found dead in the flat weeks later, because nobody was looking for him.

The game is a first-person psychological horror in **one closed apartment** with a long corridor. No chase, no combat, no loud jump scares. Dread comes from sound, light, wrong-looking people and the repetition of a daily routine that is slowly infected.

| | |
|---|---|
| Genre and camera | First-person 3D psychological horror, routine + narrative |
| Audience | Mobile players who like slow, heavy, adult horror (P.T., Visage, Layers of Fear, Lone Survivor) |
| Platforms and input | Android phone (test via web build, release via APK/AAB). Landscape. Left virtual stick = move; right side drag = look; one Use button |
| Session | 10 in-game days of about 8–12 min each; about 1.5–2 h [ASSUMPTION] |
| Engine | Godot 4.7.2, GDScript, Compatibility renderer for the web build (see D-001) |
| Look | Photographic: scanned PBR textures (CC0), warm/cold practical lights, film grade (grain, vignette, fringe, bloom) at 540p+ upscaled |
| Tone | Bleak, surreal, tragic. The ending is dark and not softened |
| References | P.T. (one corridor, repetition), Visage, Silent Hill 2 (guilt, illness), Hellblade (unreliable perception), Papers, Please (routine as engine of dread) |

## Pillars
1. **One flat, no spatial tricks.** Rooms never stretch, swap or change. All horror lives in what is *in* the rooms: sound, light, objects, a person who should not be there. This also keeps the art cost small.
2. **The routine is infected.** Every scare happens during a normal task (eating, checking the job board, brushing teeth). Mundane and wrong are mixed in the same minute.
3. **Quiet dread.** No loud stingers, no chase. Silence, tiny sounds (footsteps, a cough, laughter, knocking), lights going out, a stranger standing in the room. The uncanny figure is seen, never fought.
4. **The truth is fair.** The player believes there is an intruder; every clue to the real answer is visible from day 1 (untouched pills, one chain on the door, two plates, phone logs) and only makes sense on the ending.
5. **Photographic on a mid-range phone.** Few big baked-feeling surfaces, scanned textures, one or two dynamic lights per room, higher render height than before. Target: steady 30 fps on a Redmi Note 14 (Helio G99 Ultra) in the browser.
6. **Escalate by data.** Each day is a content file (tasks, events, phone calls, hallucinations). New days are authored, not programmed.

## Core loop
```
wake → what Martin does today (tasks) → events interrupt the tasks → night (the worst part) → next day
```
- **Seconds:** walk the flat, look, use one object; a sound from the corridor makes the player stop ([daily-routine](features/daily-routine/design.md)).
- **Minutes:** a task is interrupted by something wrong ([hallucination-director](features/hallucination-director/design.md)).
- **Session:** a day ends at sleep; the next day has new tasks and a notch more wrongness. Jack's calls ring on the landline at the far end of the corridor ([narrative](features/narrative/design.md)).

## The flat
A modest flat of about 70 m² built from boxes in `scripts/apartment.gd`. A **10.6 m corridor, 1.3 m wide** runs from the front door (south) to a window and the landline (north); every room opens off it.

| Room | Size (m) | Purpose |
|---|---|---|
| Corridor | 1.3 × 10.6 | The spine: front door (chain on), coats, long mirror, landline and window at the far end |
| Kitchen + living room | 3.0 × 6.2 | Fridge, two plates on the table, sofa, TV, desk and laptop (job search), bookshelf |
| Bedroom | 2.6 × 3.7 | Bed, wardrobe, window |
| Bathroom | 2.6 × 2.4 | Bath, mirror, damp walls |
| Dad's room (storage) | 2.6 × 4.3 | Parents' boxes, an old armchair, a family photo |
| Closet | 1.2 × 2.3 | Off the corridor; where the stranger stands |

## Feature index

| Feature | Status | Scope | Summary | Docs |
|---|---|---|---|---|
| Apartment | implemented | MVP | Corridor + 5 rooms from boxes, hinged doors, lamps per room with per-room light layers, switches, windows | — |
| Photo renderer | implemented | MVP | 3D at 360–1080p, film shader (grade, grain, vignette, fringe, bloom, `fear` and `blackout` hooks), 4 grades | — |
| Mobile controls | implemented | MVP | Floating stick, right-side look tracked per finger, Use button, debug strip (GRADE, RES, SHADOW, AA) | — |
| Menus and settings | in progress | MVP | Title, grade, brightness, sensitivity, picture height | — |
| Narrative | designed | MVP | In-engine scripted moments, inner-monologue lines, found documents, phone messages | [design](features/narrative/design.md) |
| Daily routine | designed | MVP | Task list per day (eat, job search, sleep) driving the day | [design](features/daily-routine/design.md) |
| Hallucination director | designed | MVP | Data-driven events: sounds, lights out, the stranger, never an attack | [design](features/hallucination-director/design.md) |
| Phone and landline | idea | MVP | Jack's calls and voicemails, phone gallery as a reality check | — |
| Audio | idea | MVP | Spatial 3D sounds (footsteps, cough, laughter, knock), room tone, silence as a tool | — |
| The stranger | idea | MVP | One uncanny human figure, stop-motion at 12 fps, only moves while unseen | — |
| Save and continue | idea | MVP | Autosave at sleep, one slot, `user://` | — |
| Photographic assets | idea | later | Blender-modelled furniture, baked lighting, props | — |
| Endings | idea | MVP | One ending: found dead, the unanswered phone | — |

## Milestones
1. **M0, pipeline:** web build on the phone, stick + look. *Done in Flannan Light and kept.*
2. **M1, look dev (this build):** the flat is walkable with doors and lights in the photographic look · done when: the user runs it on the Redmi Note 14 and reports FPS for each RES setting, and the corridor "feels" right.
3. **M2, one full day:** day 1 from waking to sleep with tasks, monologue, the phone and one event · done when: completable start to finish, autosave verified by quitting and continuing.
4. **M3, vertical slice (days 1–4):** the stranger, sound set, first lights-out event.
5. **M4, alpha (days 1–10)** and **M5, polish and APK.**

## Decisions

| ID | Date | Decision | Alternatives considered | Why | Affects |
|---|---|---|---|---|---|
| D-001 | 2026-11-21 | Keep Godot 4.7.2 + the web/Pages pipeline | Unreal Engine for mobile | Unreal has no web export, cannot be built in the cloud container or free CI, and every test would need an APK install; Godot gives a phone link per push | all |
| D-002 | 2026-11-21 | A closed flat with no spatial hallucinations | Rooms that stretch, a changing world | Art and build cost, and it keeps the unreliable-narrator clues fair | [hallucination-director](features/hallucination-director/design.md) |
| D-003 | 2026-11-21 | Photographic look instead of the dithered 1-bit look | Keep CRUNCH as an option | The user wants high-fidelity photo style; the flat is small enough to afford it | Photo renderer |
| D-004 | 2026-11-21 | Real-time lights per room, ambient low, no baking yet | Baked lightmaps now | Lights must be able to go out; baking comes later as indirect light only (see development plan) | Apartment |

## Change log
- 2026-11-21: New project replaces Flannan Light (v0.1).
