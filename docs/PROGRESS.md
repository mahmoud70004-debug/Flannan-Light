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

## 2026-11-22 (session 1, later)
- Blender pipeline (`tools/blender`): ~30 furniture/clutter models merged into room batches; pleated curtains, radiators, skyline outside the windows.
- Tests: use-point reachability, model existence, pause menu, scripted-event firing, whole-game bot (546 checks, ~3 min).
- Added: Jack's first voicemail on day 1 (vm0), the machine greeting in the epilogue, AUTO picture height, title flicker, reactions/hints/ambient bits, fear effects (blink, throb, lamp wavering), reduced-flash option.
- Open: playtest on the phone (performance, pacing, scare tuning, voices), APK build, merging `dev` into `main` when asked.

## Update: calls and a more natural Jack
- Voicemail queue fix (an unheard message no longer completes a later phone task), louder flies from day 1.
- Jack re-recorded (`gen_calls.py`): faster, jittered, shorter. Days 5, 7 and 9 are live calls Martin answers, flat and late, stranger each time.

## Update: after the first night on a phone
- Pictures that hung on doors were left in the air when the door opened: moved, and a check (`Apartment.hang_ok`) now fails the test if any wall item overlaps a door, arch or window.
- Real recordings for flies (much quieter, short range), knocks (a muffled one for the front door) and the light switch (also clicks when the lights go out by themselves).
- Windows: always a wet night, rain and grime, curtains drawn with a gap (the figure from day 6 shows in the gap), blinds on the bare windows; day 1 starts at 7:14 p.m.
- Pacing: one task at a time with a thought and an objective, quiet stretches, events tied to progress (see `docs/features/daily-routine/design.md`).
- Defaults: pixel filter MID, 360p, shadows on all.
- Light switches you can find in the dark: an amber pilot light on every plate, a soft halo while the room is dark, a bigger touch area, the prompt "Light switch", and the click sound on every use.

## Update v2: the story rebuilt around the flat itself
- **Why:** two nights of play gave no fear and no sense of story. See `docs/STORY-BIBLE.md`.
- **Anomalies:** each day something physical is out of place (a door open, a light on, a chair, footprints, a red coat, boxes, a flooded tub, a table set for two). Looking at one makes Martin notice it and write it in the notebook (NOTES button).
- **Waking up elsewhere:** from day 4 he wakes standing in a different room each morning (TV, front door, storage, bath, Jack's doorway, the dining table).
- **Playable nights:** 3:07 a.m., awake in the dark, a sound, find the cause, go back. From night 3 the hall light goes out; time in the dark builds dread; at full dread he loses time. Light is safe.
- **Rules:** Dr. Hale's five rules (chain, door, hall light, tablets, write things down) are taught on day 1 and broken one by one.
- **Less noise:** random events are gone, Martin explains almost nothing, the ending never says it was him.
- Fixes: floor-lamp collider, tests for colliders under large models and for solid furniture sinking into each other, switch glow, objective flow.

## Update: after the second playtest (a list of plain bugs)
- Wall shimmer: stains, ambient-occlusion quads and blob shadows lay exactly on the surfaces they decorate and z-fought. They are lifted off now, and the camera near plane is 0.12.
- Floor lamp moved to the corner by the TV and desk (it blocked the way). A "comfort" test floods the flat with a 68 cm wide body: every room and use point must be reachable.
- Interaction ray is blocked by walls and furniture: nothing can be used through a wall (tested for every light switch).
- Furniture in windows: the fridge covered the kitchen window (window moved), the TV stood in front of a window (window removed), bed windows raised. A test fails if anything tall stands in a window.
- Documents and the menu scroll by touch drag (touch is not turned into mouse input, so the scroll containers never saw it).
- Objective: top centre, appears ~9 s into day 1 (6 s later), gaps between tasks 16 s down to 10 s.
- Footsteps: soft and low. Phone: the voice comes from the handset (fades as he walks away) and he can walk during a call; handset click softer; the ring fades out.
- Start-up stalls: audio and every shader/light/object is warmed behind the first black card.
