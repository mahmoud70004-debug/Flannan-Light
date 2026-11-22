# No One Home — Game Design Document

**Version:** 0.2 · **Updated:** 2026-11-22 · [Features](#feature-index) · [Decisions](#decisions) · [Change log](#change-log)

> Replaces *Flannan Light* (lighthouse island), which is kept on branch `archive/flannan-light-v1`. The technical pipeline is unchanged; story, setting, look and name are new. "No One Home" is a working title (one constant in `scripts/title.gd`).

## Summary
Martin is in his thirties. He was a respected employee until he was fired for "misconduct and psychological problems"; he does not understand the second phrase. His parents died years ago, his only relative is his brother Jack, who lives in another state with a family of his own. Martin sits alone in a small, messy, depressing flat, and over **ten days** he becomes sure that someone, or something, is in the flat with him. He tries to hide, avoid it and find an explanation, while living an ordinary day (eating, applying for jobs, sleeping). Slowly the player understands there is no intruder: Martin has been ill all along. The game ends with him found dead in the flat weeks later, because nobody was looking for him.

The game is a first-person psychological horror in **one closed apartment** with long halls and many doors. No chase, no combat, no loud jump scares. Dread comes from sound, light, wrong-looking people and the repetition of a daily routine that is slowly infected.

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
A flat of about 95 m² built from data in `scripts/apartment.gd` (rooms on a grid; walls derived from where rooms touch; a list of doors, arches and windows). It is **T-shaped, with 13 rooms and many walls**, so nothing shows the whole flat at once: from the front door the player sees only a short hall and a closed door. Every interior door has the same 0.90 m opening (leaf 0.86 × 2.0 m, ceiling 2.5 m) and the player capsule is 0.54 m wide; the smoke test walks every door and arch in both directions.

| Room | Size (m) | Notes |
|---|---|---|
| Front hall | 1.4 × 4.6 | Front door (chain on), shoe rack, coats, dark mirror, mail on the floor; the hall door at its north end starts **closed** |
| Back hall | 1.4 × 5.4 | Landline and window at the far end; opens west through an arch into the west leg |
| West leg | 5.6 × 1.4 | Leads to the bedroom, Dad's room and Jack's old room; window at the end |
| Bathroom | 2.4 × 2.6 | Damp walls, tub with the shower curtain drawn |
| Dad's room | 2.4 × 3.4 | Boxes, his armchair, radio, family photo |
| Bedroom | 3.1 × 3.4 | Bed, wardrobe, door to the dressing room |
| Dressing room | 3.1 × 2.6 | Clothes rail, suitcase, mirror |
| Jack's old room | 3.1 × 2.6 | Old bed, desk, trophies |
| Utility | 2.4 × 2.6 | Washing machine, boiler |
| Kitchen | 4.6 × 3.0 | Two plates on the table, one person; arch to the living room |
| Living room | 4.6 × 5.0 | Sofa, TV, desk with the laptop and job applications |
| Box room | 2.2 × 2.0 | Furniture under sheets |
| Study | 2.4 × 2.0 | Old computer, files |

## Feature index

| Feature | Status | Scope | Summary | Docs |
|---|---|---|---|---|
| Apartment | implemented | MVP | T-shaped flat, 13 rooms, doors/arches/windows from data; skirting, casings, curtains, radiators, stains, fake occlusion; per-room light layers; only rooms seen through open doors are drawn | — |
| Photo renderer | implemented | MVP | 3D at 360–1080p, film shader (grade, grain, vignette, fringe, bloom, `fear` and `blackout` hooks), 4 grades | — |
| Pixel/dither filter (FX) | implemented | MVP | Stacks on any grade: pixel blocks, fewer colour levels and a Bayer dither that grow with `fear`; OFF / LOW / MID / HIGH / AUTO (AUTO ramps over about ten minutes with spikes; events call `boost_fear`) | — |
| Mobile controls | implemented | MVP | Floating stick, right-side look tracked per finger, Use button, debug strip (GRADE, RES, SHADOW, FX) | — |
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
| D-005 | 2026-11-22 | Camera 60° vertical FOV, player capsule 0.27 m, one door standard (0.90 m) | 72° FOV, 0.35 m capsule, mixed door widths | 72° vertical is about 116° horizontal on a 20:9 phone, which stretched doors and rooms; a 0.70 m wide player could not use 0.70–0.80 m doors | Apartment |
| D-006 | 2026-11-22 | T-shaped layout with a closed hall door, 13 rooms, no room more than 1.8:1 | One straight corridor with rooms off it | Playtest: one straight corridor reads as unreal and shows everything | Apartment |
| D-007 | 2026-11-22 | Hide rooms not reachable through open doors (draw calls 200 → 40–75) | Occlusion culling | CPU-side occlusion is too costly in the single-threaded web build | Apartment |
| D-008 | 2026-11-22 | The pixel/dither filter is a separate setting on top of the grade, driven by fear | A fifth grade | The look must degrade as tension rises, and be tunable independently of colour | Pixel/dither filter |
| D-004 | 2026-11-21 | Real-time lights per room, ambient low, no baking yet | Baked lightmaps now | Lights must be able to go out; baking comes later as indirect light only (see development plan) | Apartment |

## Change log
- 2026-11-22: Flat redesigned (T-shape, 13 rooms, standard doors, detail pass); pixel/dither filter added; FOV and player size fixed (v0.2).
- 2026-11-21: New project replaces Flannan Light (v0.1).
