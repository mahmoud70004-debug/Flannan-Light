# Flannan Light — Game Design Document

**Version:** 0.7 · **Updated:** 2026-11-19 · [Features](#feature-index) · [Decisions](#decisions) · [Change log](#change-log)

## Summary
You are a new lighthouse keeper in the early 1900s, alone on a remote island in an archipelago run by a government superintendent, Martin. Martin teaches you the daily routine on day 1, sails away, and visits every few days. You clean the tower, check the lamp, keep the store, watch ships and signal the far lighthouses. The routine is calm and repetitive on purpose; then it starts to break. The game is psychological horror through exploration only: no monsters, no combat. It ends when Martin, your only link to the world, starts to behave wrongly and you learn what the routine has been hiding.

Inspired by the 1900 disappearance of the three keepers of the Flannan Isles lighthouse. All characters, names and events in the game are fictional.

| | |
|---|---|
| Genre and camera | First-person 3D psychological horror, routine sim |
| Audience | Core mobile players who like slow-burn horror (Lone Survivor, Iron Lung, Lethal Company-style dread without combat) |
| Platforms and input | Android phone (test via web build, release via APK/AAB). Landscape. Left virtual stick = move; whole right side = look (drag); one Interact button |
| Session | 10 in-game days of about 10–14 min each; 2–2.5 h total [ASSUMPTION] |
| Engine | Godot 4.7 (4.7.2), GDScript, Compatibility renderer [ASSUMPTION — see D-001] |
| Scope | Small commercial release: itch.io + Google Play |
| References | Papers, Please (routine as the engine of dread), Iron Lung (isolation, restricted view), Return of the Obra Dinn / Playdead-era 1-bit looks (dithered B/W) |

## Pillars
1. **The routine is the game.** Every horror beat is a deviation from a task the player already knows by heart; no new system is introduced just to scare.
2. **Nothing attacks you.** No combat, no chase, no jump scares, no loud stingers. Dread comes from wrongness, absence and silence. A glimpse never pays off with an attack: the light cuts out, comes back, and the thing is gone.
3. **Martin is the last anchor.** His visits are the only safety; the horror peaks when that safety is corrupted. His dialogue changes by tiny edits, never by a sudden turn.
4. **One-bit and cheap.** Pure black-and-white, low-res, dithered. Lighting, silhouette and dither carry the art, so assets stay simple and the game runs on mid-range phones.
5. **Escalate by data, not code.** Each day is a content file; new anomalies are authored, not programmed.

## Core loop
```
wake → Martin's/log instructions → do daily tasks (clean, check lamp, store, watch ships, signal) → sleep → next day (a little more wrong)
```
- **Seconds:** walk, look, interact with one object ([daily-routine](features/daily-routine/design.md)).
- **Minutes:** a ship appears, you identify its bearing and signal the far lighthouses ([ship-signaling](features/ship-signaling/design.md)).
- **Session:** a day ends at sleep; the next day adds anomalies from the day's data ([anomaly-escalation](features/anomaly-escalation/design.md)); Martin visits on days 1, 3, 5, 7, 9.

## Feature index

| Feature | Status | Scope | Summary | Docs |
|---|---|---|---|---|
| Daily routine | designed | MVP | Task list per day: clean tower/bedroom, check lamp faults, tidy store, sleep | [design](features/daily-routine/design.md) |
| Ship signaling | designed | MVP | Spot a ship, read its bearing, signal the far lighthouses with the shutter lamp | [design](features/ship-signaling/design.md) |
| Anomaly escalation | designed | MVP | Data-driven anomalies, tiers 0–4, plus Martin's visit scripts | [design](features/anomaly-escalation/design.md) |
| Mobile controls | implemented | MVP | Floating left stick, right-side drag look tracked per finger (web touch relative is unreliable), Interact button | — |
| 1-bit renderer | idea | MVP | Low-res SubViewport, nearest filter, ordered-dither B/W shader | — |
| Island | in progress | MVP | Island modelled in Blender from the outline of a real island: cliffs, sea stacks, surf, a gentle path (about 4 degrees) from the quay to the lighthouse gate | — |
| Lighthouse | in progress | MVP | 17.8 m tower, keepers' building, compound wall (Blender). Hall, stair door, stairs down, store door, underground store (game-built) | — |
| Doors | in progress | MVP | Hinged door with eased open/close; aim at the leaf or the opening to toggle | — |
| Menus and settings | idea | MVP | Title, new/continue, settings (sensitivity, brightness, dither, volume), pause | — |
| Save and continue | idea | MVP | Autosave at sleep, one slot, stored in `user://` | — |
| Martin dialogue | idea | MVP | Text-only dialogue with scripted variants per visit | — |
| Audio | idea | MVP | Fixed soundscape: silence, waves, storm, gulls; indoor low-pass; no music or stingers | — |
| Glimpse events | idea | MVP | A grinning face seen for ~2 s in dim light during a task, then lights cut and return and it is gone; never attacks | — |
| Visual style (PHOTO / CRUNCH) | in progress | MVP | Two post looks to choose between: CRUNCH (dithered palette) and PHOTO (24 tones, film grain, halation, soft edges); STYLE button toggles live | — |
| Visual filters | idea | MVP | Selectable looks in Settings: pure 1-bit, 4-tone ash, warm dither, cold tide, reference palette | — |
| Endings | idea | later | Three endings chosen by routine fidelity and final choice | — |

## Milestones
1. **M0, pipeline:** empty scene with stick + look on the user's phone via a web link · done when: user opens the link on their Android phone, moves, looks, and sees the build number.
2. **M1a, look dev (the store room):** one fully lit reference room · done when: the user finds it readable and unsettling in one chosen filter, with draw calls under 100.
2. **M1b, greybox island and lighthouse:** walkable exterior and interiors · done when: 60 fps on the user's phone with the 1-bit shader on.
3. **M2, one full routine day:** all MVP tasks on day 1 + sleep + save · done when: day 1 is completable start to finish with the autosave verified by quitting and continuing.
4. **M3, vertical slice:** days 1–4 incl. Martin's first visit and the first anomaly · done when: a tester finishes it and reports the first anomaly as unsettling, not confusing.
5. **M4, alpha:** all 10 days, placeholder audio/art · done when: playable start to ending without blockers.
6. **M5, beta:** final art/audio, performance, settings, accessibility · done when: no crash in 3 consecutive full playthroughs on the user's phone; build size within budget.
7. **M6, release:** itch.io page + Google Play · done when: signed AAB passes Play review; itch build live.

## Direction
- **Tone and narrative:** quiet, dry, bureaucratic. The log book is a diegetic narrator. Dread comes from small mismatches (counts, directions, handwriting, time). Stays ambiguous: the player never gets a monster to explain it.
- **Art:** low-res, ordered dither, very dim lighting. Pure black and white is no longer mandatory: Settings offers several palette presets (see Visual filters) and the user picks the one that fits the mood. The face and figure style references a dithered, grinning, deep-black-eyed look (user reference); we design an original character, not a copy.
- **Audio:** the soundscape is fixed for the whole game and never replaced: silence, violent waves, storm wind, gulls. No music and no stingers. Interior acoustics (a low-pass on the sea bus indoors) give silence and muffled waves without changing the sound set. Diegetic foley (steps, doors, task sounds) exists but is quiet.
- **Accessibility and localization:** English only at launch; strings in a translation table from day one so adding a language does not touch code. Brightness and dither-strength settings; no flashing above 3 Hz outside the lamp rotation (which is slow).
- **Content rules:** the 1900 disappearance is history. Do not quote Wilfrid Gibson's 1912 poem "Flannan Isle" (probably still in copyright) and do not base scenes on the 2018 film. Use only invented names for characters.

## Game-level acceptance
- 60 fps target and 30 fps floor on the user's Android phone; ≤ 100 draw calls; ≤ 50k visible triangles.
- Test build (Web) ≤ 40 MB download; first load ≤ 15 s on mobile data [ASSUMPTION].
- A first-time player completes day 1 without reading anything outside the game.

## Decisions

| ID | Date | Decision | Alternatives considered | Why | Affects |
|---|---|---|---|---|---|
| D-001 | 2026-11-19 | Godot 4.7.2, GDScript, Compatibility renderer | three.js (web only), Unity 6.3 (heavy web/mobile build) | One project yields a web build for instant phone testing and an Android build for release; web export uses Compatibility anyway, so mobile and web look the same | all |
| D-002 | 2026-11-19 | Test builds ship as a web build on GitHub Pages (single-threaded); APK only for the final release | APK artifact per commit | User's requirement: a link per update; single-threaded needs no COOP/COEP headers, which Pages cannot set | M0 |
| D-003 | 2026-11-19 | Text and UI in English only | Arabic + English | User choice; Arabic would need RTL shaping and a pixel font | UI, dialogue |
| D-004 | 2026-11-19 | Days are data resources (`DayData`) | hard-coded day scripts | Slow escalation becomes content authoring | [anomaly-escalation](features/anomaly-escalation/design.md) |
| D-006 | 2026-11-19 | Fixed soundscape: silence, waves, storm, gulls; no music, no stingers | add a score or stingers | User direction: terror from silence and escalation, never loud sounds | Audio |
| D-007 | 2026-11-19 | Palette presets in Settings instead of mandatory pure B/W; user picks by playtesting | pure 1-bit only | User allows colours; palette swap is a cheap lookup in the dither shader | Visual filters |
| D-008 | 2026-11-19 | Test link is GitHub Pages at `https://mahmoud70004-debug.github.io/Flannan-Light/`, auto-deployed by Actions on every push to `main` | Cloudflare/Netlify | User's required link format | M0 |
| D-009 | 2026-11-20 | Outdoor and indoor lighting separated by visual layers (outdoor layer 1, interior layer 2); hut walls carry an outer skin on layer 1 | one shared light set | Moonlight must not reach the store room through walls; no shadows needed | Island, Store room |
| D-010 | 2026-11-20 | Dither default 0.5 with a selectable grain size; texture pixel noise reduced | keep full dither | User: too many dither dots, but never smooth. Hard bands plus crisp edges instead of heavy noise | Visual filters |
| D-011 | 2026-11-20 | Day 1 starts in overcast daylight, at the end of the jetty; dusk and night are later presets (`Atmosphere`) | start at night | User: the game must not begin at night. Daylight also sells the 1900 feel and makes the later nights land harder | Atmosphere, [anomaly-escalation](features/anomaly-escalation/design.md) |
| D-012 | 2026-11-20 | Default look is ASH; SILVER (cool grey between ASH and COLD) added; COLD kept | REFERENCE default | User picked ASH then COLD for the 1900 feel | Visual filters |
| D-013 | 2026-11-20 | Island and lighthouse are authored in Blender by script and exported as glTF; generated assets are committed | procedural-only terrain in GDScript | User asked for Blender-quality shapes; a real island outline (user's reference) gives a believable form; CI stays Blender-free | Island, Lighthouse |
| D-014 | 2026-11-20 | Lighthouse is 17.8 m (was 28 m placeholder). The store is underground, reached from the hall by a stair door, stairs and a store door | store in a separate hut | User: shorter tower, internal lower door to an underground store | Lighthouse, [daily-routine](features/daily-routine/design.md) |
| D-015 | 2026-11-20 | Default render height 360 (options 240-540); sun shadows on by default (SHADOW button cycles) | 240 | User agreed to raise resolution; their phone ran 65 fps at 360 in build 4 | Settings |
| D-005 | 2026-11-19 | 3D renders in a low-res SubViewport, UI in the native-res window | one low-res window for all | Crisp UI at no extra GPU cost, pixel look for the world | 1-bit renderer |

## Open questions
- **Assumptions to confirm:** 10 days of about 12 min [ASSUMPTION]; Godot Compatibility renderer; "soft" grey option [ASSUMPTION]; three endings [ASSUMPTION]; Martin's dialogue is text only [ASSUMPTION].
- **Risks:**
  - Pure 1-bit may be unreadable in dark scenes → readability test on the real phone in M1, brightness/dither settings.
  - Godot web on mid-range Android may stutter or run out of memory → performance spike in M0/M1 on the real phone before content.
  - Web audio needs a user tap → the title screen's Start button unlocks audio.
  - GitHub Pages needs a public repo (or a paid plan) → the repo is made public; the source is therefore visible (see DEVELOPMENT-PLAN).
  - Glimpses can be missed on a small dim screen, or become predictable → gaze-triggered placement, a strict per-day budget, and every glimpse different (see DEVELOPMENT-PLAN).
  - Horror pacing is hard to judge solo → a playtest per milestone from M3.

## Change log
**0.1 (2026-11-19):** first draft; three core features designed; D-001 to D-005 logged.
**0.7 (2026-11-21):** PHOTO vs CRUNCH look switch for the art-direction decision; scrollable title menu.
**0.6 (2026-11-20):** Blender island and lighthouse, underground store, 360p default; D-013 to D-015.
**0.5 (2026-11-20):** daylight start, time-of-day presets, whitewashed tower, faceted rocks, ASH default; D-011, D-012.
**0.4 (2026-11-20):** island, door animation, lighting layers; D-009, D-010.
**0.3 (2026-11-20):** look-dev phase added (store room, edge/contrast/vignette pass, merged geometry); touch look fixed.
**0.2 (2026-11-19):** audio fixed (D-006), palette presets (D-007), deploy link (D-008); glimpse events and visual filters added to the index; pillar 2 rewritten.
