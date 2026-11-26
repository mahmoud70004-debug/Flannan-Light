# Flannan Light — Complete Project Handoff

> **ملاحظة للمالك:** هذا الملف مكتوب بالإنجليزية لأنه موجّه لأي نموذج أو وكيل ذكاء اصطناعي يكمل العمل؛ اقتباسات توجيهاتك الأساسية محفوظة بنصها العربي داخله. أعطه هذا الملف كما هو.

**Last updated:** 2026-11-26 · **Current build:** 22 (published, awaiting the owner's phone test) · **Studio:** Pottsfield Studio

This document is the single source of truth for continuing the game *Flannan Light*. It records the owner's vision, the story, every decision already made, the art direction, how the game is built, exactly where work stopped, and the rules that must not be broken. If anything here conflicts with older files in the repository (notably `docs/GDD.md` v0.7), **this document wins**.

---

## 0. Read this first: how to work on this project

1. **Your role.** You are the game's developer and executive producer at Pottsfield Studio. The owner is the creative director. You build, test, publish and report. The owner decides vision, story and look.
2. **Language.** Talk to the owner **in Arabic**. The game itself is in **English** (the main language, final). Arabic may be added as a translation only at the very end. Code, commits and in-game text are in English.
3. **Never invent canon.** Story facts, characters, endings and the art direction below are decided. Do not add characters, change the ending, add combat, give the player a voice, or move the setting. When something is not decided (see §12 "Open questions"), **ask the owner** with concrete options and a recommendation. The owner likes being asked good questions before story work starts ("لك حرية سؤالي قدر ما تريد من الاسئلة").
4. **Plans are dynamic.** The owner said plans are "not fixed but dynamic" and may change with how the game looks. Propose; don't lock things in silently.
5. **Every update must be testable on the owner's phone** through the public web link, and must be a **visible, substantial** change. The owner rejected build 21 with "لم ارى تغيير ملموس" ("I saw no tangible change"). Primitive bugs (falling off a walkway, one-sided railings, walking through walls) are unacceptable to them.
6. **Before you publish:** run the automated tests (§10.6), take screenshots and compare them side by side with the reference images (§6.2). Only then push to `main`.
7. **Report after publishing (in Arabic):** what changed, what was broken before and is fixed, walking times, known issues, the build number, and the link with `?v=<build>` so the phone does not show a cached build. Ask for FPS when the scene got heavier.

---

## 1. The owner

- Creative director of Pottsfield Studio. Writes in Arabic.
- Tests every build on a **Redmi Note 14 (MediaTek Helio G99 Ultra)** through the GitHub Pages link, in landscape, with touch controls. On the abandoned flat project they measured 30–35 FPS minimum at highest settings; the lighthouse builds were reported "very smooth".
- Judges by direct visual comparison with reference images and by playing. Notices detail, scale and realism problems (door sizes, terrain that feels like climbing a plateau, interiors that make no architectural sense).
- Wants psychological horror that is **gradual, silent, dark and surreal**, never cheap or random.
- Gave the agent freedom to use any engine, tool, repository skill or integration that makes the game better. Skills live in their repository `awesome-gamedev-agent-skills`.

---

## 2. The game in one paragraph

You are **Christopher**, a new lighthouse keeper arriving in **1900** at a tiny, isolated island in an uninhabited northern archipelago. **Martin**, superintendent of the Northern Lighthouse Board, brings you by boat, teaches you the routine, gives you a phonograph wax cylinder with instructions, and sails away. Each day you do morning tasks (lamp, lens, oil, clockwork, log, weather, ships, light signals with far lighthouses, the store) and then sleep. The routine slowly breaks: small wrong things, a silent unexplained presence glimpsed only 5–6 times, rare night awakenings that are the most terrifying moments, and finally Martin's later visits, which are hallucinations: he knows things that happened to you, and the far lighthouse signals that the boat never sailed. On day 14 the relief crew lands and finds the lamp lit, the log complete to the last line, and nobody on the island.

Inspired by the atmosphere and real details of the 1900 Flannan Isles lighthouse disappearance. **It is fiction, not a retelling.** All names and events are invented.

---

## 3. Pillars (non-negotiable)

1. **The routine is the game.** Every scare is a deviation from a task the player already knows. Build the routine first, then break it gradually. Horror must never be random, cheap or clichéd. The owner wrote: "يجب بناء روتين ثم كسره بالتدريج حتى لا يكون الرعب عشوائي ورخيص ومبتذل".
2. **Silent, dark, surreal psychological horror.** Constant unease ("هاجس نفسي مستمر ورعب نفسي صامت جدا وسوداوي سريالي"). No combat, no chases, no supernatural spectacle, no loud stingers. Footsteps, running, sudden light, absence, wrongness.
3. **Isolation is total.** No other characters except Martin. No civilian island, no settlement, no rescue. Martin is the only safety and the only link to the world, and that safety is corrupted at the climax.
4. **Black and white, cold and harsh. The only warmth is the hand lantern.**
5. **Mobile-first and cheap to render.** A small world allows higher quality in lighting and materials, but it must stay smooth on a mid-range phone.

---

## 4. Story bible (decided)

### 4.1 Characters
- **Christopher (player).**
  - Completely silent: no voice, no dialogue choices.
  - Simple backstory, revealed only through **diary entries**. They are written automatically at the end of some days, Outlast-style, with a small notification, and reading them is optional.
  - Diaries are separate from the official lighthouse log, which is a task.
  - Occasional very short "thinking aloud" text lines during tasks, rare, and **never during a scary moment**.
  - No cutscenes for backstory.
- **Martin.** Superintendent of the Northern Lighthouse Board.
  - Visits about every 3 days with supplies, plus some surprise visits.
  - Early on he is the guide and only source of safety.
  - **Truth: his late visits are hallucinations. "Martin is not Martin": he never came.** The owner's words: "مارتن ليس مارتن ببساطة... يُهلوس ان مارتن جاء، ومارتن لم يزوره في ذلك اليوم اصلا".
  - In late visits he behaves strangely and says things that actually happened to the player when alone.
  - He speaks with a **generated voice**.
- **The presence ("the other being").**
  - Seen in different forms, as **flashes**, only **5–6 times** in the whole game, appearing gradually.
  - Uncanny-valley face, utterly terrifying, then it runs away into the dark and is gone.
  - No explanation; the reading leans slightly toward madness and hallucination from loneliness.
  - Sound language: silence, then barefoot running moving away; footsteps; walking; sudden light.
- **Previous keepers.** Fictional names. They leave hidden documents and strange belongings to find.
- **The relief crew.** Appears only in the ending.

### 4.2 Opening
- The game opens **on the boat**. Martin chats, asks and answers his own questions, and Christopher stays silent. Gameplay begins when the boat reaches the landing.
- Before leaving, Martin hands over an **Edison phonograph wax cylinder**, which is period-accurate, with recorded instructions. Later the phonograph plays by itself, or a sentence appears on the cylinder that was not there before.
- **The instructions explain the light signals:** the code book, how to read them and how to reply.
- **Martin establishes the isolation indirectly, without any civilian island.** The owner explicitly flagged that a supply base must not imply a nearby town. The agreed facts:
  - the tender sails from the mainland, two days away, and serves many lighthouses;
  - the archipelago is uninhabited;
  - the far lighthouses are kept by lone men like you;
  - "if the boat doesn't come, nobody comes."

### 4.3 The quiet proof of hallucination
On a "visit" day, the far lighthouse signals that the boat **did not sail** because of the storm, and the supplies Martin "brought" are **not in the store**.

### 4.4 Ending (single ending)
- Day 14: the relief crew arrives and finds the lamp lit and the log written to the last line, with no one on the island.
- A silent final shot through their eyes.
- The owner noted this matches, and even offers one explanation of, the real incident.

### 4.5 Days (draft, agreed direction)

| Day | Routine | What breaks |
|---|---|---|
| 1 | Arrival with Martin, tour, cylinder, first tasks, first diary | Nothing |
| 2–3 | Lamp, log, telescope, store | A door open; wet footprints on the stairs |
| 4 | Martin's visit (real) | Clockwork fault |
| 5 | Store with the lantern | **Appearance:** the face in the store, then running in the dark |
| 6 | Normal day | **Night:** a light wakes him; footsteps on the gravel |
| 7 | Martin's last real visit | Martin tired; a hint about the previous keeper |
| 8 | Telescope | **Appearance:** a figure on the far rocks in the fog |
| 9 | **Surprise visit (hallucination)** | Martin mentions what happened in the store; signal: the boat never sailed |
| 10 | More faults | **Night:** running on the tower stairs |
| 11 | Phonograph plays by itself | A new sentence on the cylinder |
| 12 | **Visit (hallucination)** | Martin knows details of night 10 |
| 13 | Silent day, thick fog | **Appearance:** behind him on the stairs |
| 14 | Ending | — |

Length target: **14 days, about 2 hours** of play.

### 4.6 Day structure and tasks
- **Morning tasks, then sleep. No night shifts.** Sunrise and sunset are deliberately excluded because they are costly and weaken the contrast between foggy white day and black night.
- **Night is rare.** It happens only when something wakes the player at midnight: light, steps, running. These must be **the most frightening and most desolate moments**, with the player trapped in the dark. Total darkness; only the rotating beam passes through the window.
- **All tasks are mandatory objectives.** The player cannot skip them. Each day has 3–5 of these, plus one fault or change to break monotony even on days with no horror:
  - clean the lens and the lantern room;
  - oil and wick;
  - wind the clockwork;
  - write the log and the weather (barometer);
  - watch for ships with the telescope;
  - exchange light signals with the far lighthouses;
  - put the underground store in order;
  - sound the fog horn on fog days.
- **Optional exploration:** hidden documents, strange items left by previous keepers, locked drawers, and the telescope. These keep the player engaged.
- **The underground store is completely dark.** The player carries a lantern that lights about 3 m or less. This is a core fear device.
- **Design intent from the owner, to be discussed before building:** strange hints should be placed by a **smart system that watches the player** (where they look, what they are doing) and puts anomalies in front of them or during tasks unexpectedly, not on a fixed timer and not necessarily daily. The early days must be completely normal.

---

## 5. The place

### 5.1 Island
- Tiny island; the terrain was sculpted in Blender from an aerial photo of a real island (`reference_images/04_island_shape_reference_aerial.jpg`): rocky cliffs, surf, and sea stacks.
- **Cliff-top plateau at 10.5 m** where the tower stands.
- The rest of the island is lower grassland and rock at about 5–6 m, rising to a rocky hump in the west.

### 5.2 Landing (matches reference 02, built in build 22)
- A **dock at sea level** (deck at 1.0 m), 10.6 m long, inside a small rocky cove, separated from the island by **big boulders**.
- A **wooden switchback stair** climbs from the dock up the cliff face: three flights with two landings, deliberately **not straight**, which is what the owner asked for. The stair is cut into the rock.
- Rope railing with posts on both sides, and lamps on posts at the turns.
- **Invisible continuous rail walls (1.25 m) on both sides**, from the dock end to the top of the stair. The dock end is closed.
- The top of the stair opens onto the cliff-top, which can be explored freely.

### 5.3 The lighthouse tower (matches reference 01, built in build 22)
- **Exterior:**
  - tall, tapered, whitewashed coursed masonry: outer radius 3.75 m at the base, 3.05 m at the top, masonry 17.4 m high;
  - slit windows with drip stones and a darker stone door surround;
  - a corbelled **gallery** with an iron railing;
  - a **glazed lantern room** with astragals, a dark cone roof and a vent ball;
  - a rotating **beam** and **halo** at night;
  - the door faces the top of the landing stair, i.e. seaward.
- **Ground floor, with everything visible from the entrance:**
  - **Ahead:** the door to the **keeper's bedroom**, a small narrow lean-to behind the tower with a narrow bed, small iron stove, table and chair, shelf, small window and an oil lamp. The owner asked for "غرفة خلفية للمنارة من الاسفل ضيقة وصغيرة لنوم الحارس".
  - **Right:** a **simple interior door to the oil store**. This is a stone shed beside the tower with benches and oil cans, and a straight stair down to the **underground store**: sacks, barrels and shelves, pitch dark, lit only by the hand lantern.
  - **Left:** the **stone spiral stair**, cantilevered steps hugging the wall with an iron baluster rail on the open side. It makes 3 turns (5.8 m per turn) up to the lantern room. A door from the lantern room leads out onto the gallery.
- The entrance door is hinged on the right so it opens against the free wall and never blocks the foot of the stair.

### 5.4 Interiors still to come
Lantern mechanism details, a watch or log desk, the barometer, the phonograph, the telescope, and a place for the signal lamp or flag. These are all needed by tasks; design them with the owner.

---

## 6. Art direction

### 6.1 Rules
- **Black and white, like the references.** Grey everything: all light sources and materials are greyscale.
- **The only warmth is the hand lantern's ambient yellow glow**, in the store and at night. The owner: "يُشعر اللاعب بأن عالم اللعبة بارد وقاسي ومصدر الامان والدفئ الوحيد هو الفانوس الذي في يده".
- **Atmosphere:** fog, rain, heavy storm clouds, a halo round the lamp, and beam shafts.
- **Day is pale, foggy and white; night is total black** with only the beam.
- **Detail matters.** The owner rejected flat, textureless, washed-out looks: "الاضاءة لازالت تطمس التفاصيل ولازالت اللعبة بلا خامات وبلا تفاصيل رسومية". Use real textures with normal maps (masonry, rock, flagstone, wood), strong contrast, a key light with shadows and low ambient light. Never let lighting wash out detail.
- **Earlier critique to remember:** "بلا روح او هوية بصرية واضحة" (no soul, no clear visual identity). Every visual pass must strengthen identity: silhouette of the tower, the beam, the cold sea, the warm lantern.
- **Default look:** PHOTO mode (film grade: tones, grain 0.05, halation, rain on screen, no rain indoors), at **360p** internal resolution. CRUNCH mode (dithered palette) remains as an option.
  - The owner once found heavy dither dots annoying, but does not want the game "smooth/soft" either.
  - Palette preferred earlier: **ASH**, then COLD.

### 6.2 Reference images (in the backup zip, `reference_images/`)
1. `01_lighthouse_reference_tower_night.jpg`: tall tapered white masonry tower at night from its base, beam shafts, halo, door at the base, rain, heavy clouds. **The target for the tower and the night look.**
2. `02_lighthouse_reference_stair_to_sea.jpg`: a long steep wooden stair on posts with a rope railing and lamps, descending from the tower down to the sea among rocks and surf. **The target for the landing.**
3. `03_stair_reference_sent_with_last_feedback.jpg`: the same stair idea, sent with the build 21 rejection.
4. `04_island_shape_reference_aerial.jpg`: real island shape (cliffs, a lighthouse on top, paths).
5. `05_early_style_reference.jpg`: early pixel/dither style reference from day one (historical).
6. `06_screenshot_from_abandoned_flat_project.jpg`: from the cancelled project (not a target).

### 6.3 Audio direction
- **Ambient:** sea, wind and rain loops, muffled underground. They are generated by Python scripts in `tools/audio/` and encoded to `.ogg`.
- **Horror sound:** silence first; barefoot running, footsteps, a door. No loud stingers.
- **Martin's voice:** generated with **Kokoro TTS**, the same tool used before.
  - **The voice for Martin in this game has not been chosen yet.** Generate a few candidates and let the owner choose, as was done before; the owner picked from candidates last time.
  - Earlier lesson: generated dialogue sounded robotic until it got natural pauses, emotion (sadness, worry) and short lines.
- The owner provided real sound files earlier (fly, light switch, knocking; see `your_uploaded_sounds/`). Real recorded sounds are welcome.

---

## 7. Controls and UI
- First person, landscape:
  - **left virtual stick** to move;
  - **the whole right side** of the screen to look by dragging;
  - **one interact button**;
  - a **MENU** button.
- Do not restyle the controls without being asked.
- **Title screen:** Start; look options (style CRUNCH/PHOTO, palette, picture height 240/360/480/540, shadows, dither grain); brightness; sensitivity; build label.
- The build label (`build N · commit`) is shown so the owner can confirm which build they are playing.
- Settings are saved in `user://settings.cfg`. **Whenever defaults change, bump `Settings.LOOK_VERSION`** so old phone settings are discarded. Old 240p settings once hid an entire visual update from the owner.

---

## 8. History (so you understand the owner's reactions)

1. **19–21 Nov: Flannan Light v1.**
   - Built: GDD, a dithered B/W renderer, touch controls, Pages deploy, a Blender island from the aerial photo, a short lighthouse with an underground store, and the PHOTO/CRUNCH switch.
   - The owner said it had no soul or identity and the tower interior was bad, and cancelled it.
   - Archived as tag `flannan-light-final` and branch `archive-v1`.
2. **21–24 Nov: "No One Home" (cancelled).**
   - A psychological horror game in a flat. **Its protagonist was also named Martin.** He was an unemployed man going mad, with a brother Jack who left voicemails voiced by Kokoro `bm_onyx`, chosen by the owner.
   - Built: a 13-room flat, ten days, phone and voicemails, anomalies, playable nights.
   - The owner felt no fear after two nights and hit repeated "stupid" bugs: wall shimmer, furniture overlaps, using items through walls. They gave up: "لقد فقدت الامل تماما في ذلك المشروع".
   - Archived on branch `archive/no-one-home-v2`.
   - **Do not mix it into Flannan Light.** Jack, the flat and the unemployed Martin do not exist here. In Flannan Light, **Martin is the superintendent**.
3. **24 Nov – now: Flannan Light v3.**
   - Story decided (§4).
   - **Build 21** (Phase 1, "look and place"): rejected. Its failures:
     - a flat pier with no terrain;
     - a railing on one side only;
     - the player could step off the raised boardwalk and never get back;
     - lighting that washed out detail, and no textures;
     - a tower unlike the reference, and the store impossible to find.
   - **Build 22**: everything rebuilt (§5), with textures, lighting, containment tests and old-settings reset. Published, **awaiting the owner's test.**

---

## 9. Build plan (each phase ends with the owner testing on the phone)

1. **Look and place.** Build 22 delivered it; awaiting approval or feedback.
2. **First slice.** The boat with Martin (voiced), the whole of day 1, the phonograph cylinder, the first tasks, the first diary entry, sleep.
3. **Days 2–4.** Tasks, faults, documents.
4. **Days 5–10.** Appearances and nights.
5. **Days 11–14.** Hallucinated Martin, the ending, polish.

Do not build many days before one day has been tested on the phone.

---

## 10. Technical implementation

### 10.1 Stack and repository
- **Godot 4.7.2**, Compatibility renderer (GL), GDScript. Web export for testing; Android APK/AAB later.
- **Repository:** `mahmoud70004-debug/Flannan-Light` (public).
  - Branches: `main` is what is published; `lighthouse` mirrors the latest lighthouse work; `archive-v1` and tag `flannan-light-final` hold v1; `archive/no-one-home-v2` holds the cancelled project; `downloads` holds the backup zip.
- **Play link:** https://mahmoud70004-debug.github.io/Flannan-Light/ (add `?v=<build>`).
- **Full backup at build 22:** https://github.com/mahmoud70004-debug/Flannan-Light/raw/downloads/FlannanLight_backup_2026-11-26.zip

### 10.2 Rendering pipeline
- The 3D world renders into a low-res `SubViewport` (default 360 px high) and is shown full screen through `shaders/dither_palette.gdshader`.
  - **Modes:** PHOTO (many tones, grain, halation) and CRUNCH (palette quantisation with dither).
  - The shader also does screen-space **rain**, which is turned off indoors, and **warmth**: warm tint is applied after quantising only where the scene is warm, i.e. lit by the hand lantern, since all other sources are grey.
- **Light layers:** outdoors is layer 1 (sun or moon); interiors are layer 2 (their own lights). Daylight never leaks into rooms.
- **Sky:** an opaque cloud dome (`shaders/sky_clouds.gdshader`) that follows the camera and glows toward the lantern at night. It must stay opaque, or it draws over the beam shafts.
- **Fog:** environment fog, pale by day and black by night. Time-of-day presets (day, dusk, night) are in `scripts/atmosphere.gd`. Day: ambient 0.30, key light 1.35, shadows on.

### 10.3 Main scripts (`game/scripts/`)

| File | Role |
|---|---|
| `world.gd` | Builds view, island, tower, player and UI. Hand lantern on at night or underground. Rain off indoors. **Safe-spot logic:** the safe spot updates only on the walk, the cliff-top or indoors; touching the sea (y < 0.1) returns you there. Debug spawns via `?spawn=` / `--spawn=` (see list below) and `?time=night`. |
| `island.gd` | Loads `assets/models/island.glb` and builds terrain collision, sea, sky, **dock and stair** (one mitred polyline: continuous walking surface and both rail walls in one collision mesh; planks, treads on stringers, posts, rope, lamps, night halos) and **boulders** (noise-deformed, convex colliders). `cut_terrain()` removes terrain under the oil-store stair. Public: `walk_points()`, `on_walk()`, `seaward()`, `tower_yaw()`, `door_point()`, `spawn_point()`, `top_height()`. |
| `lighthouse.gd` | The tower **built entirely in code**. Constants: `R_IN 2.75`, `R_BASE 3.75`, `R_TOP 3.05`, `TOP_Y 17.4`, `PITCH 5.8`, `TURNS 3`, `STAIR_START -15°`, `STORE_FLOOR_Y -3.4`. The spiral is a smooth helical ramp collider plus visual steps plus a continuous inner rail wall. Doors: `entrance_door`, `stair_door` (oil store), `bedroom_door`. Also `is_indoors()`, `lantern_world()`, `set_beam()`, `set_porch()`. Local frame: +Z is the door side, angles in degrees from +Z toward +X. |
| `store_room.gd` | The underground store (props; no light of its own when underground). |
| `mesh_builder.gd` | Quads, prisms, ring sectors and ribbons with auto-winding and matching collision triangles. |
| `tex.gd` | Procedural greyscale textures (masonry, rock, flagstone, bricks, planks, burlap, rough, plaster), cached, with generated normal maps; world-space triplanar materials. |
| `room_kit.gd` | Batched static geometry per material, solids with collision, hinged doors (`door.gd`, `door_catch.gd`). |
| `player.gd` | Capsule (radius 0.35, height 1.7), walk speed 2.2, `floor_max_angle` 46°, hand lantern (warm light, range 3.4). |
| `settings.gd`, `title.gd`, `touch_controls.gd`, `hud.gd`, `build_info.gd`, `palettes.gd`, `audio.gd`, `sfx.gd`, `weather_sound.gd` | Settings, title screen, controls, HUD, build label, palettes, audio. |

Debug spawn views: `dock`, `stair`, `gate`, `door`, `tower_look`, `inside`, `stairs`, `store`, `shed`, `bedroom`, `top`, `gallery`, `pier_top`, `sky`.

### 10.4 Terrain pipeline (`tools/blender/`)
- `island_data.py` builds the heightfield (1 m grid) from the traced island outline. It contains the cliff-top (`TOP_H 10.5`), the cove slope, the carved stair (`nodes` in seaward and along-coast metres from the old landing), the dock (`DECK_H 1.0`) and the boulder placement.
- `build_island.py` is run with a Python that has `bpy numpy scipy pillow`. It writes `island.glb`, `island_meta.json` (lighthouse, seaward, door, stair, dock, deck_h, top_h, boulders, stacks, bounds) and `shore_mask.png`.
- Coordinates: Blender (x east, y north, z up) maps to Godot (x, z, −y).

### 10.5 Hard-won technical rules
- A `CharacterBody3D` cannot climb real risers. **Every stair needs a smooth sloped collider**; steps are visual only.
- **Ropes are visual. Railings need continuous collision walls about 1.2 m high on both sides**, with no gaps at the joins.
- Never leave a place where the player can fall and not return. The safe spot must never be a slope or a rock.
- Doors must not block a path when open. Hinge them against free wall.
- No coplanar overlapping surfaces (shimmer), no furniture intersecting, no interaction through walls.
- Bump the settings version when defaults change.
- Measure walking times. Long, empty walks bore the owner.

### 10.6 Tests, screenshots and deploy
- **Tests:** `godot --headless --path game --script res://tests/smoke.gd`. It fails on any `FAIL`, `SCRIPT ERROR`, `SHADER ERROR` or `ERROR`. There are **57 checks** at build 22. A real body:
  - walks dock to top and back;
  - is shoved against the rails 28 times;
  - walks off the cliff-top in 16 directions and must be able to come back or be in the sea;
  - climbs and descends the spiral, and is shoved off its open side and into the top hole;
  - walks the gallery railing all round;
  - reaches the store and the bedroom.
  - Old 240p settings must be replaced by the new defaults.

  Walking times at build 22:

  | Route | Time |
  |---|---|
  | Dock end to top of stair | 16 s |
  | Climb the spiral | 23 s |
  | Descend the spiral | 20 s |
  | Ground floor to store | 5 s |

- **Screenshots:** Godot Movie Maker under xvfb, for example `--write-movie out.png --fixed-fps 30 --quit-after 8 res://scenes/world.tscn -- --spawn=tower_look --time=night`. Delete the saved settings in the xvfb profile first. Compare with the references side by side.
- **Deploy:** every push to `main` runs `.github/workflows/deploy.yml`: import, smoke test, web export named by run number (`b<N>.html`), then GitHub Pages. The build number equals the workflow run number. If Pages fails with "Multiple artifacts", start a fresh `workflow_dispatch` run rather than a re-run.
- Develop on a working branch; push to `main` only for a release the owner should test. A docs-only push to `main` still creates a new build number.

---

## 11. Current status (stopping point)

- **Build 22 is live** and the owner is about to test it.
- **Known issues in build 22:**
  - boulders are still somewhat angular;
  - the surf foam is basic;
  - from directly below at night, the lantern room reads as a dark mass because the gallery hides the glowing glazing;
  - triangle count rose to about 75–92k per view.
- **Asked of the owner:** FPS on the Redmi Note 14 at 360p.
- **Next step:**
  - Wait for the owner's verdict on build 22 and fix everything they report first.
  - Then Phase 2 (the first slice: boat, day 1, cylinder, first diary, sleep), after settling the open questions below with them.

## 12. Open questions (ask the owner; do not decide alone)

1. Martin's voice: generate Kokoro candidates and let the owner pick. Decide the tone of his early versus late (hallucinated) visits.
2. The phonograph cylinder script: exact instructions, signal code explanation, and the isolation lines.
3. The boat opening: how long, what the player can do during it, and how arrival transitions into play.
4. Task interaction design for mobile: how cleaning, oiling, winding, logging, telescope and signalling work with one interact button.
5. The diary and log UI, and the notification style.
6. The "smart hint system" that watches the player: its rules and limits.
7. The forms of the presence for each of its 5–6 appearances, beyond the store face.
8. Christopher's simple backstory (diary content).
9. Names of the previous keepers, and what their documents and items reveal.

## 13. Never do

- Never add combat, chases, jump-scare stingers, random timed scares, or supernatural spectacle.
- Never give Christopher a voice or dialogue choices, and never tell his backstory through cutscenes.
- Never add other characters, a civilian island, a town, or any rescue route.
- Never add sunrise or sunset or night shifts. Night appears only as rare awakenings.
- Never add colour, other than the hand lantern's warmth.
- Never change the ending, the 1900 setting, or the meaning of Martin's late visits.
- Never retell the real Flannan keepers' story or use their names.
- Never publish without tests, screenshots and comparison with the references.
- Never ship walkways without both-side collision rails, or areas the player can fall into and not leave.
- Never revive elements of the cancelled flat project.

## 14. Older documents in the repository
- `docs/PLAN-v3.md` (Arabic): the v3 story plan; consistent with this file.
- `docs/GDD.md` (v0.7, 19 Nov) and `docs/DEVELOPMENT-PLAN.md`: historical. **Superseded where they conflict.** They describe 10 days instead of 14, "no monsters" where v3 now has the presence seen in flashes, and a "welcome" ending where v3 has the relief-crew ending.
- The owner's complete messages, verbatim and dated: `docs/03_تعليماتك_وإرشاداتك_بالنص_الكامل.md` in the backup zip.
