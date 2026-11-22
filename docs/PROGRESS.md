# Progress log (working notes, newest first)

Branch policy: work goes to `dev` (tests run, nothing deploys). `main` deploys the web build and only
gets a merge when the user asks. Jack's voice: `am_onyx` (kokoro-onnx), more pauses, sad and worried, not slow.

## Plan for the full-game pass (started 2026-11-22)
1. Audio: synthesise SFX and generate Jack's voicemails (`tools/tts/`), ship as OGG in `game/assets/audio/`.
2. Flat v3: living room (heart, large) + kitchen corner + entry + 2 bedrooms + storage + bathroom, far fewer walls,
   clear aisles (a reachability test floods the floor with a player-sized capsule).
3. Decay: rotten food, flies (shader swarm + positional buzz that rises on approach), kitchen trash corner with empty beer bottles.
4. Game systems: GameState (days, tasks, clues, fear, save), Days data (10 days), tasks and interactions,
   dialogue/monologue, documents, phone and answering machine, camera (empty photos), hallucination director, the stranger, endings.
5. Test (a scripted bot plays all 10 days), polish, docs.

## Done
- (see git log on `dev`)

## 2026-11-22 (full-game pass, session 1)
- Done on `dev`: audio (SFX synth + Jack's voicemails with caption JSON), flat v3 (open plan, rot, flies, trash corner),
  GameState/Days/Docs/Story/Director/Stranger/Ambience/Sfx/HUD, title with Continue, a bot in the smoke test that plays all
  ten days and the ending (472 checks, ~2 min).
- Web export checked in Chromium/SwiftShader: title -> new game -> day card -> game loads, no console errors.
- Next: visual polish pass (trash corner, epilogue, stranger look), more content (TV, calendar, mirror, peephole),
  tune pacing/difficulty, more documents, update GDD/plan docs, performance look at fx levels.
