extends SceneTree
## Headless smoke test: run with
##   godot --headless --path game --script res://tests/smoke.gd
## Exits 1 on the first failure. Cannot judge rendering (no GPU), only that scripts, scenes,
## data and collisions are sound. The flat is checked as data: every door and arch is walked
## through in both directions by a real CharacterBody3D, every spawn spot must be free of
## geometry, and the entrance must not see down the whole hall.

var _failed := false
var gs                      # the GameState autoload (not visible to the compiler when this script is loaded)


func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		_failed = true


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	gs = root.get_node("GameState")
	Audio.muted = true
	# Film grades, the filter and the shader
	var shader := load("res://shaders/film_post.gdshader") as Shader
	_check(shader != null, "film shader loads")
	var need := ["sat", "shadow", "high", "contrast", "grain", "vignette"]
	for i in Film.GRADES.size():
		var g: Dictionary = Film.GRADES[i]
		var missing := need.filter(func(k: String) -> bool: return not g.has(k))
		_check(missing.is_empty(), "grade %s has every key %s" % [Film.grade_name(i), missing])
	_check(Film.fx_amount(0, 0.9) == 0.0 and Film.fx_amount(Film.FX_AUTO, 0.7) == 0.7, "fx: OFF is zero, AUTO follows fear")
	var mat := ShaderMaterial.new()
	mat.shader = shader
	Film.apply(mat, 0, 1.0, 0.0)
	_check(mat.get_shader_parameter("levels") == 256.0, "fx at 0 leaves the picture alone")
	Film.apply(mat, 0, 1.0, 1.0)
	_check(mat.get_shader_parameter("pixel_size") > 3.0 and mat.get_shader_parameter("levels") < 10.0, "fx at 1 is chunky and low-colour")

	# Every material builds, and textured ones really have their textures
	for key in Mats.TABLE:
		var m := Mats.get_mat(key)
		var textured: bool = (Mats.TABLE[key] as Dictionary)["tex"] != ""
		_check(m != null and (not textured or (m.albedo_texture != null and m.normal_texture != null)), "material %s" % key)

	# Scenes instantiate and survive a few frames
	Engine.set_meta("overrides", {"spawn": "door", "no_title": "1"})
	for path in ["res://scenes/title.tscn", "res://scenes/world.tscn"]:
		var packed := load(path) as PackedScene
		_check(packed != null, "%s loads" % path)
		if packed:
			var inst := packed.instantiate()
			root.add_child(inst)
			await process_frame
			await process_frame
			_check(is_instance_valid(inst), "%s runs two frames" % path)
			if path.ends_with("world.tscn"):
				await _exercise_menu(inst)
			inst.queue_free()
			await process_frame

	# The flat, as data
	var flat := Apartment.new()
	root.add_child(flat)
	await process_frame
	await physics_frame
	await physics_frame
	var space := root.get_world_3d().direct_space_state
	_check(flat.hang_errors.is_empty(), "no picture, switch or hook sits on a door, arch or window %s" % str(flat.hang_errors))

	for name in Apartment.CELLS:
		var r: Array = Apartment.CELLS[name]["r"]
		var w: float = r[1] - r[0]
		var d: float = r[3] - r[2]
		if name != "hall":
			_check(maxf(w, d) / minf(w, d) <= 1.8, "%s is room-shaped (%.1f x %.1f m)" % [name, w, d])
		_check(flat.lamps.has(name) and not (flat.lamps[name] as Array).is_empty(), "%s has a lamp" % name)
		var cx: float = (r[0] + r[1]) * 0.5
		var cz: float = (r[2] + r[3]) * 0.5
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(cx, 2.3, cz), Vector3(cx, -1.0, cz)))
		_check(not hit.is_empty(), "there is a floor in %s" % name)
	var door_names: Array = []
	for o in Apartment.OPENINGS:
		if o["kind"] == "door":
			door_names.append(o["name"])
			_check(is_equal_approx(o["w"], Apartment.DOOR_W), "door %s has the standard %.2f m opening" % [o["name"], Apartment.DOOR_W])
			_check(flat.doors.has(o["name"]), "door %s exists" % o["name"])
	_check(flat.front_door != null, "front door exists")

	# Spawn and look-dev spots must be free for a player-sized capsule
	var spots: Dictionary = flat.debug_spots()
	spots["spawn"] = [flat.spawn_point(), 0.0, 0.0]
	spots["wake"] = [flat.wake_point(), flat.wake_yaw(), 0.0]
	var cap := CapsuleShape3D.new()
	cap.radius = 0.27
	cap.height = 1.7
	for name in spots:
		if name == "wake_bed2":
			continue                                   # a doorway: checked with the doors open
		var p: Vector3 = spots[name][0]
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = cap
		q.transform = Transform3D(Basis(), p + Vector3(0, 0.88, 0))
		q.collision_mask = 1
		var floor_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3(0, 0.5, 0), p - Vector3(0, 1.0, 0)))
		_check(space.intersect_shape(q, 1).is_empty() and not floor_hit.is_empty(), "spot '%s' is free and on the floor" % name)

	# The entrance must not show the whole flat: the phone at the far end of the hall is hidden
	var eye := flat.spawn_point() + Vector3(0, 1.6, 0)
	var sight := space.intersect_ray(PhysicsRayQueryParameters3D.create(eye, Vector3(-6.0, 0.9, -4.9)))
	_check(not sight.is_empty() and sight.position.x > -2.0, "from the front door the phone is hidden behind walls")

	# Stranger spots must be free floor
	for spot in flat.stranger_spots:
		var qs := PhysicsShapeQueryParameters3D.new()
		qs.shape = cap
		qs.transform = Transform3D(Basis(), spot + Vector3(0, 0.88, 0))
		qs.collision_mask = 1
		_check(space.intersect_shape(qs, 1).is_empty() and flat.cell_at(spot) != "", "stranger spot (%.1f, %.1f) is free in %s" % [spot.x, spot.z, flat.cell_at(spot)])
	_check(flat.movables.has("coat") and flat.movables.has("body"), "the coat and the epilogue body exist as movables")

	# Every model the furnishings ask for exists (a missing one silently falls back to boxes)
	var src := FileAccess.get_file_as_string("res://scripts/furnishings.gd") + FileAccess.get_file_as_string("res://scripts/apartment.gd")
	var rx := RegEx.new()
	rx.compile("place_model\\(\"([a-z0-9_]+)\"")
	var seen := {}
	for m in rx.search_all(src):
		seen[m.get_string(1)] = true
	for k in Furnishings.TABLES.values():
		seen[k] = true
	for m_name in seen:
		_check(ResourceLoader.exists("res://assets/models/props/%s.glb" % m_name), "model '%s' exists" % m_name)

	# The story as data: every task step is something in the flat, every sound and message exists
	_check_story_content(flat)

	# Lights and switches
	_check(flat.room_lit("entry"), "entry lamps start on")
	flat.toggle_room("entry")
	_check(not flat.room_lit("entry"), "a switch turns the entry lamps off")
	flat.toggle_room("entry")
	flat.apply_shadows(2)
	flat.apply_shadows(0)

	# Doors swing
	for d in ["bed1", "bath"]:
		var door = flat.doors[d]
		_check(not door.is_open, "%s door starts closed" % d)
		door.interact()
		await create_timer(1.1).timeout
		_check(door.is_open and absf(door.rotation_degrees.y - door.open_angle) < 0.5, "%s door swings open" % d)
		door.interact()
		await create_timer(1.0).timeout
		_check(not door.is_open and absf(door.rotation_degrees.y) < 0.5, "%s door swings closed" % d)

	# Only rooms the player can see through open openings are drawn
	var viewer := Node3D.new()
	root.add_child(viewer)
	viewer.global_position = flat.spawn_point()
	flat.viewer = viewer
	await process_frame
	await process_frame
	var vis: Array = flat.visible_cells("entry")
	_check("living" in vis and "kitchen" in vis and not ("bath" in vis) and not ("bed1" in vis), "from the entry you see the living room and kitchen, not the bedrooms %s" % [vis])
	vis = flat.visible_cells("hall")
	_check(not ("bed1" in vis), "closed bedroom doors hide the bedrooms from the hall")
	flat.doors["bed1"].set_open(true, false)
	vis = flat.visible_cells("hall")
	_check("bed1" in vis, "an open bedroom door shows the bedroom %s" % [vis])
	await process_frame
	await process_frame
	var hidden_bath := true
	for n in flat.cull_items:
		if n.layers == Apartment.L_BATH and n.visible:
			hidden_bath = false
	_check(hidden_bath, "bathroom meshes are hidden from the entry")
	flat.doors["bed1"].set_open(false, false)
	flat.viewer = null
	viewer.queue_free()

	await _walk_openings(flat)
	await _reachability(flat)
	await _use_points_work(flat)
	await _furniture_checks(flat)
	flat.queue_free()
	await process_frame

	await _playthrough()
	await _voicemail_order()
	await _pacing()
	await _save_roundtrip()
	await _fuzz()

	# Settings round-trip
	var s := root.get_node_or_null("Settings")
	_check(s != null, "Settings autoload present")
	if s:
		s.grade = 1
		s.fx = 2
		s.save()
		_check(FileAccess.file_exists("user://settings.cfg"), "settings file written")
		s.grade = 0
		s.fx = 4
		s.save()

	await process_frame
	await process_frame
	await process_frame
	quit(1 if _failed else 0)


## A real CharacterBody3D walks through every door and arch, in both directions. If furniture or
## geometry leaves less room than the player needs, or a door does not let him through, it fails.
func _walk_openings(flat) -> void:
	var player = (load("res://scripts/player.gd") as GDScript).new()
	root.add_child(player)
	var trips: Array = []
	for name in flat.doors:
		var info: Dictionary = flat.door_info[name]
		trips.append([name, info["center"], info["normal"]])
	for o in Apartment.OPENINGS:
		if o["kind"] == "arch":
			var along := Vector3(1, 0, 0) if o["axis"] == "z" else Vector3(0, 0, 1)
			var normal := Vector3(0, 0, 1) if o["axis"] == "z" else Vector3(1, 0, 0)
			var centre: Vector3 = Vector3(o["c"], 0, o["fixed"]) if o["axis"] == "z" else Vector3(o["fixed"], 0, o["c"])
			trips.append(["arch@%.1f,%.1f" % [centre.x, centre.z], centre, normal])
	for t in trips:
		var centre: Vector3 = t[1]
		var n: Vector3 = t[2]
		if t[0] in flat.doors:
			flat.doors[t[0]].set_open(true, false)
			await physics_frame
		for dir in [1.0, -1.0]:
			var start: Vector3 = centre - n * 0.55 * dir
			player.position = Vector3(start.x, 0.05, start.z)
			var heading: Vector3 = n * dir
			player.rotation.y = atan2(-heading.x, -heading.z)
			player.velocity = Vector3.ZERO
			await physics_frame
			await _walk(player, Vector2(0, -1), 1.0)
			var progress: float = (Vector3(player.position.x, 0, player.position.z) - centre).dot(heading)
			_check(progress > 0.8, "walked through %s %s (%.2f m past the doorway)" % [t[0], "forwards" if dir > 0.0 else "back", progress])
		if t[0] in flat.doors:
			flat.doors[t[0]].set_open(false, false)

	# The front door holds
	player.position = Vector3(0.1, 0.05, -0.8)
	player.rotation.y = PI
	await _walk(player, Vector2(0, -1), 1.5)
	_check(player.position.z > -0.5 and player.position.z < 0.05, "the front door holds (z=%.2f)" % player.position.z)

	player.queue_free()


func _walk(player, dir: Vector2, seconds: float) -> void:
	player.move_input = dir
	var frames := int(seconds * 60.0)
	for i in frames:
		await physics_frame
	player.move_input = Vector2.ZERO


## Floods the floor with a slightly fat player capsule from the spawn point, with every door open.
## Everything must be connected (no pocket you can see but never reach), every prop the game uses
## must be within reach of a reachable spot, and each room must be mostly walkable.
func _reachability(flat) -> void:
	for d in flat.doors:
		flat.doors[d].set_open(true, false)
	await physics_frame
	await physics_frame
	var space := root.get_world_3d().direct_space_state
	var cap := CapsuleShape3D.new()
	cap.radius = 0.30
	cap.height = 1.7
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cap
	q.collision_mask = 1
	var f: Array = flat.footprint()
	var step := 0.2
	var nx := int((f[1] - f[0]) / step) + 1
	var nz := int((f[3] - f[2]) / step) + 1
	var free := {}
	for ix in nx:
		for iz in nz:
			var p := Vector3(f[0] + ix * step, 0.0, f[2] + iz * step)
			if flat.cell_at(p) == "":
				continue
			q.transform = Transform3D(Basis(), p + Vector3(0, 0.95, 0))
			if space.intersect_shape(q, 1).is_empty():
				free[Vector2i(ix, iz)] = p
	var start := Vector2i(int(round((flat.spawn_point().x - f[0]) / step)), int(round((flat.spawn_point().z - f[2]) / step)))
	_check(free.has(start), "the spawn cell is free for the fat capsule")
	var seen := {start: true}
	var queue := [start]
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nb: Vector2i = cur + d
			if free.has(nb) and not seen.has(nb):
				seen[nb] = true
				queue.push_back(nb)
	var per_room := {}
	for k in free:
		var c: String = flat.cell_at(free[k])
		var e: Array = per_room.get(c, [0, 0])
		e[0] += 1
		if seen.has(k):
			e[1] += 1
		per_room[c] = e
	for c in per_room:
		var e: Array = per_room[c]
		var area := float(e[1]) * step * step
		_check(e[1] >= e[0] - 6, "%s has no unreachable pockets (%d of %d free cells reachable)" % [c, e[1], e[0]])
		_check(area >= 1.2, "%s has %.1f m2 of walkable floor" % [c, area])
	for id in flat.pois:
		var pos: Vector3 = flat.pois[id]
		var best := 99.0
		for k in seen:
			var p: Vector3 = free[k]
			best = minf(best, Vector2(p.x - pos.x, p.z - pos.z).length())
		_check(best <= 1.25, "'%s' can be reached (nearest standing spot %.2f m)" % [id, best])
	for d in flat.doors:
		flat.doors[d].set_open(false, false)




func _check_story_content(flat) -> void:
	var director = (load("res://scripts/director.gd") as GDScript).new()
	var valid_ids: Array = flat.use_points.keys() + [Days.PHOTO_STEP, "bed1"]
	var sounds := ["step_0", "step_3", "cough_0", "cough_1", "knock3", "knock1", "knock3_front", "switch", "door_creak", "lamp_buzz", "breath", "whisper_0", "whisper_4", "laugh_0", "laugh_1", "tv_static", "phone_ring", "handset", "machine_new", "machine_end", "machine_beep", "shutter", "click", "drip", "heartbeat", "drone", "room_tone", "street", "fridge_hum", "flies_loop", "jack_greeting", "greeting", "vm0", "tap_run", "chair_scrape", "chain_rattle", "dial_tone", "whisper_0"]
	for n in sounds:
		_check(Audio.stream(n) != null, "sound '%s' exists" % n)
	for i in range(1, Days.COUNT + 1):
		var d: Dictionary = Days.get_day(i)
		var ids := {}
		for t in d["tasks"]:
			_check(not ids.has(t["id"]), "day %d: task id '%s' is unique" % [i, t["id"]])
			ids[t["id"]] = true
			for step in t["steps"]:
				_check(step in valid_ids, "day %d: step '%s' is something in the flat" % [i, step])
			if t.has("doc"):
				_check(Docs.LIST.has(t["doc"]) and Docs.get_doc(t["doc"])["body"] != "", "day %d: document '%s' exists" % [i, t["doc"]])
			if t.has("vm"):
				_check(FileAccess.file_exists("res://assets/audio/%s.json" % t["vm"]) and Audio.stream(t["vm"]) != null, "day %d: voicemail '%s' exists with captions" % [i, t["vm"]])
		for s in d["scripted"]:
			_check(director.has_method("_ev_" + s["do"]), "day %d: scripted event '%s' exists" % [i, s["do"]])
		for e in d["events"]["pool"]:
			_check(director.has_method("_ev_" + e), "day %d: random event '%s' exists" % [i, e])
		_check(Apartment.WAKE.has(d["wake"]), "day %d: he wakes at a real place (%s)" % [i, d["wake"]])
		for room in d["lit"]:
			_check(flat.lamps.has(room), "day %d: room '%s' has a lamp to start lit" % [i, room])
		for id in d["anomalies"]:
			_check(Days.ANOMALY.has(id) and Days.ANOMALY[id]["evidence"] != "" and not (Days.ANOMALY[id]["lines"] as Array).is_empty(), "day %d: anomaly '%s' is defined" % [i, id])
			_check(flat.movables.has(id) or id in ["door_bed1", "kitchen_light", "all_lit"], "day %d: anomaly '%s' has something to see" % [i, id])
		var night: Dictionary = d["night"]
		if not night.is_empty():
			_check(night["cue"] in ["tap", "knock", "chair", "phone", "breath", "clock", "steps", "tv", "chain"], "day %d: night cue '%s' exists" % [i, night["cue"]])
			_check(night["target"] in valid_ids and night["found"].size() > 0 and night["evidence"] != "", "day %d: the night's target '%s' is something in the flat" % [i, night["target"]])
			_check(night["stranger"] in ["", "hall", "living", "bed2"], "day %d: the night's figure is placed in a real room" % i)
			_check((i <= 2) == (not night["dark"]), "day %d: the first two nights teach (light), the rest are dark" % i)
		_check(d["tasks"][-1]["id"] == "lock_up" or d.get("final", false), "day %d ends with locking up (the rules are the routine)" % i)
		_check(d["fear"] >= 0.0 and d["fear"] <= 1.0 and d["flies"] >= 0.0, "day %d: fear and flies are in range" % i)
	var last_fear := 0.0
	for i in range(1, Days.COUNT + 1):                  # the dread only climbs, and never by more than a step
		var f: float = Days.get_day(i)["fear"]
		_check(f > last_fear and f - last_fear <= 0.12, "day %d: fear rises by a step (%.2f to %.2f)" % [i, last_fear, f])
		last_fear = f
	for id in Days.EXAMINE:
		_check(id in valid_ids, "examine text is for a real prop: %s" % id)
	for k in Docs.LIST:
		_check(Docs.LIST[k]["body"].length() > 20, "document %s has text" % k)
	director.free()


## The night: wake at 3:07, hear the sound, go to the thing, find it, go back to bed.
func _bot_night(story, hud, data: Dictionary) -> void:
	var n: Dictionary = data["night"]
	var t0 := Time.get_ticks_msec()
	while (story._phase != "night" or hud.objective_text() != str(n["obj"])) and (Time.get_ticks_msec() - t0) < 90000:
		await process_frame
		if hud.doc_open:
			hud.close_doc()
	_check(story._phase == "night" and hud.objective_text() == str(n["obj"]), "night %d: he wakes at 3:07 and the objective is '%s'" % [gs.day, n["obj"]])
	story.on_used("bed1")                               # not yet: he wants to know what that was
	await process_frame
	_check(not story._night_found, "night %d: he will not go back to sleep before he has looked" % gs.day)
	await _bot_use(story, hud, str(n["target"]))
	_check(story._night_found and gs.has_evidence("night_%d" % gs.day), "night %d: finding it goes in the notebook" % gs.day)
	t0 = Time.get_ticks_msec()
	while hud.objective_text() != "Go back to bed" and (Time.get_ticks_msec() - t0) < 30000:
		await process_frame
	story.on_used("bed1")


## A bot plays the whole game at ten times speed: every day's tasks, every random event once, the
## nights, the last day, the ending and the epilogue. Nothing may error and the story must finish.
func _playthrough() -> void:
	Engine.time_scale = 10.0
	Engine.set_meta("overrides", {"spawn": "door", "no_title": "1"})
	var w = (load("res://scenes/world.tscn") as PackedScene).instantiate()
	root.add_child(w)
	await process_frame
	await process_frame
	var story = w._story
	var apartment: Apartment = w._apartment
	var hud = w._hud
	var director = w._director
	var stranger: Stranger = w._stranger
	var done := [false]
	story.finished.connect(func() -> void: done[0] = true)
	gs.new_game()
	director.enabled = true                           # the debug scene switches it off
	await story.start_day()
	_check(story.is_free() and gs.day == 1, "day 1 begins after the card")
	for day in range(1, Days.COUNT + 1):
		var data: Dictionary = Days.get_day(day)
		_check(gs.day == day, "the game is on day %d" % day)
		for ev in data["events"]["pool"]:
			await director.fire(ev)
			stranger.vanish()
		for t in data["tasks"]:
			if t.has("vm") or data.has("vm"):
				await director.fire("phone_ring")
			await _wait_announce(story, t["id"])
			_check(hud.objective_text() != "" or story._announced == t["id"], "day %d: '%s' is announced as the objective" % [day, t["id"]])
			for step in t["steps"]:
				await _bot_use(story, hud, step)
			_check(gs.is_done(t["id"]), "day %d: task '%s' completes" % [day, t["id"]])
		if data.get("final", false):
			break
		# The last task being done hurries whatever scripted moments are left; the bed waits for them
		var tw := Time.get_ticks_msec()
		while not director.all_scripted_fired() and (Time.get_ticks_msec() - tw) < 90000:
			director.update(0.1)                       # the world does not run the director in this debug scene
			await process_frame
		_check(director.all_scripted_fired(), "day %d: every scripted event fires" % day)
		story.on_used("bed1")
		if not (data["night"] as Dictionary).is_empty():
			await _bot_night(story, hud, data)
		var waited := 0.0
		var t0 := Time.get_ticks_msec()
		while (gs.day != day + 1 or not story.is_free()) and waited < 120.0:
			await process_frame
			waited = (Time.get_ticks_msec() - t0) / 1000.0
			if hud.doc_open:
				hud.close_doc()
		_check(gs.day == day + 1 and story.is_free(), "sleeping on day %d leads to day %d" % [day, day + 1])
	var waited2 := 0.0
	var t0b := Time.get_ticks_msec()
	while not stranger.final_mode and waited2 < 60.0:
		await process_frame
		waited2 = (Time.get_ticks_msec() - t0b) / 1000.0
	_check(stranger.final_mode and stranger.state != Stranger.State.HIDDEN, "on the last day the stranger waits in the living room")
	story._ending()
	waited2 = 0.0
	var t0c := Time.get_ticks_msec()
	while not done[0] and waited2 < 200.0:
		await process_frame
		waited2 = (Time.get_ticks_msec() - t0c) / 1000.0
		if hud.doc_open:
			hud.close_doc()
	_check(done[0], "the ending and the epilogue play to the end")
	_check(gs.ended, "the save marks the game as finished")
	Engine.time_scale = 1.0
	gs.erase()
	w.queue_free()
	await process_frame
	await process_frame


## The bot waits for Martin to get to a task (the thought, then the objective).
func _wait_announce(story, id: String) -> void:
	story._task_timer = 0.0
	var hud = story.hud
	var t0 := Time.get_ticks_msec()
	while (story._announced != id or hud.objective_text() == "") and (Time.get_ticks_msec() - t0) < 60000:
		await process_frame
	await process_frame


func _bot_use(story, hud, id: String) -> void:
	if id == Days.PHOTO_STEP:
		story.take_photo()
		await process_frame
		return
	story.on_used(id)
	var waited := 0.0
	var t0 := Time.get_ticks_msec()
	while waited < 90.0:
		await process_frame
		waited = (Time.get_ticks_msec() - t0) / 1000.0
		if hud.doc_open:
			hud.close_doc()
		if story.is_free():
			break


## The pause menu opens, every row works (each press rebuilds the menu), and RESUME unpauses.
func _exercise_menu(w) -> void:
	w._toggle_menu()
	await process_frame
	_check(w._hud.menu_open and paused, "the pause menu opens and pauses the game")
	var rows: int = w._hud.find_child("Box", true, false).get_child_count()
	_check(rows >= 8, "the pause menu has %d rows" % rows)
	for i in range(1, rows - 1):
		var box = w._hud.find_child("Box", true, false)
		if i < box.get_child_count():
			(box.get_child(i) as Button).pressed.emit()
		await process_frame
		await process_frame
	var box2 = w._hud.find_child("Box", true, false)
	(box2.get_child(0) as Button).pressed.emit()
	await process_frame
	_check(not w._hud.menu_open and not paused, "RESUME closes the menu and unpauses")
	for k in ["Settings"]:
		var st = root.get_node(k)
		st.reduce_flash = false
		st.volume = 1.0
		st.show_debug = false
		st.grade = 0
		st.fx = 4
		st.shadows = 0
		st.msaa = 0
		st.render_height = 540
		st.save()


## Anything big the player can see has something solid under it, and solid things do not sink into each other.
func _furniture_checks(flat) -> void:
	await physics_frame
	var space := root.get_world_3d().direct_space_state
	var probe := SphereShape3D.new()
	probe.radius = 0.05
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = probe
	q.collision_mask = 1
	var cap := CapsuleShape3D.new()
	cap.radius = 0.27
	cap.height = 1.7
	var wq := PhysicsShapeQueryParameters3D.new()
	wq.shape = cap
	wq.collision_mask = 1
	for wid in Apartment.WAKE:
		var wp: Vector3 = Apartment.WAKE[wid][0]
		wq.transform = Transform3D(Basis(), wp + Vector3(0, 0.88, 0))
		_check(space.intersect_shape(wq, 1).is_empty(), "he can wake at '%s' without standing inside anything" % wid)
	var open_models: Array = []
	for m in flat.placed_models:
		var bb: AABB = m["aabb"]
		if bb.size.x < 0.3 or bb.size.z < 0.3 or bb.size.y < 0.6 or m["name"] in ["curtain", "radiator"]:
			continue
		var hit := false
		var y := 0.08
		while y < minf(bb.end.y, 1.9) and not hit:
			q.transform = Transform3D(Basis(), Vector3(bb.get_center().x, y, bb.get_center().z))
			hit = not space.intersect_shape(q, 1).is_empty()
			y += 0.1
		if not hit:
			open_models.append("%s at (%.1f, %.1f)" % [m["name"], bb.get_center().x, bb.get_center().z])
	_check(open_models.is_empty(), "every large model has a collider under it %s" % [open_models])
	# Solid boxes (not walls) must not sink into each other
	var boxes: Array = []
	for n in flat._body.get_children():
		var cs := n as CollisionShape3D
		if cs and cs.shape is BoxShape3D:
			var size: Vector3 = (cs.shape as BoxShape3D).size
			if size.y > 2.3 or maxf(size.x, size.z) > 6.0:
				continue                                  # walls and slabs
			boxes.append(cs.transform * AABB(-size * 0.5, size))
	var clashes: Array = []
	for i in boxes.size():
		for j in range(i + 1, boxes.size()):
			var a: AABB = boxes[i]
			var b: AABB = boxes[j]
			var inter := a.intersection(b)
			if inter.size.x > 0.12 and inter.size.z > 0.12 and inter.size.y > 0.15:
				clashes.append("(%.1f, %.1f) %s / %s" % [inter.get_center().x, inter.get_center().z, a.size, b.size])
	_check(clashes.is_empty(), "solid furniture does not sink into other furniture %s" % [clashes])


## Every prop the game uses can really be used: from somewhere the player can stand, looking at it, the
## interaction ray finds it (and not something else in front of it).
func _use_points_work(flat) -> void:
	for d in flat.doors:
		flat.doors[d].set_open(true, false)
	flat.set_use("note", true)                         # (it only exists on day 9)
	var player = (load("res://scripts/player.gd") as GDScript).new()
	root.add_child(player)
	await physics_frame
	var space := root.get_world_3d().direct_space_state
	var cap := CapsuleShape3D.new()
	cap.radius = 0.28
	cap.height = 1.7
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cap
	q.collision_mask = 1
	for id in flat.use_points:
		var it = flat.use_points[id]
		var center: Vector3 = it.global_position
		var found := false
		for r in [0.9, 1.2, 1.5]:
			for k in 16:
				var ang := TAU * float(k) / 16.0
				var pos := Vector3(center.x + cos(ang) * r, 0.05, center.z + sin(ang) * r)
				if flat.cell_at(pos) == "":
					continue
				q.transform = Transform3D(Basis(), pos + Vector3(0, 0.9, 0))
				if not space.intersect_shape(q, 1).is_empty():
					continue
				player.position = pos
				var d := center - Vector3(pos.x, 1.6, pos.z)
				player.rotation.y = atan2(-d.x, -d.z)
				player.set_pitch(atan2(d.y, Vector2(d.x, d.z).length()))
				await physics_frame
				await physics_frame
				var t = player.target()
				if t != null and t == it:
					found = true
					break
			if found:
				break
		_check(found, "'%s' can be used from a spot the player can stand on" % id)
	player.queue_free()
	for d in flat.doors:
		flat.doors[d].set_open(false, false)


## A message nobody listened to must not stand in for the one a phone task is waiting for.
func _voicemail_order() -> void:
	Engine.time_scale = 10.0
	Engine.set_meta("overrides", {"spawn": "door", "no_title": "1"})
	var w = (load("res://scenes/world.tscn") as PackedScene).instantiate()
	root.add_child(w)
	await process_frame
	await process_frame
	var story = w._story
	var hud = w._hud
	w._director.enabled = false
	# Day 4 with vm0 (day 1) unheard: the machine plays vm0 then vm1, and the task is done
	gs.new_game()
	gs.queue_vm("vm0")
	gs.day = 4
	gs.finish_task("photo")                             # the phone task comes second
	await story.start_day()
	await _wait_announce(story, "phone")
	_check(gs.pending == ["vm0", "vm1"], "day 4: the old and the new message are waiting once the phone task begins")
	await _bot_use(story, hud, "phone")
	_check(gs.heard.has("vm0") and gs.heard.has("vm1") and gs.pending.is_empty(), "both messages are heard, oldest first")
	_check(gs.is_done("phone"), "day 4: the phone task completes once vm1 has played")
	# Day 7 with vm2 (day 5, nobody asked for it) unheard: vm3 is still the task's message
	gs.new_game()
	gs.queue_vm("vm2")
	gs.day = 7
	gs.finish_task("pills")                             # the phone task comes second
	await story.start_day()
	await _wait_announce(story, "phone")
	_check(not gs.is_done("phone"), "day 7: the phone task is not done before anyone answers")
	await _bot_use(story, hud, "phone")
	_check(gs.heard.has("vm2") and gs.heard.has("vm3") and gs.is_done("phone"), "day 7: vm3 is heard and finishes the task even with vm2 unheard")
	w.queue_free()
	await process_frame
	Engine.time_scale = 1.0


## The pacing: one task at a time, a thought before each objective, a quiet stretch after it.
func _pacing() -> void:
	Engine.time_scale = 10.0
	Engine.set_meta("overrides", {"spawn": "door", "no_title": "1"})
	var w = (load("res://scenes/world.tscn") as PackedScene).instantiate()
	root.add_child(w)
	await process_frame
	await process_frame
	var story = w._story
	var hud = w._hud
	w._director.enabled = false
	gs.new_game()
	await story.start_day()
	var fresh = (load("res://scripts/settings.gd") as GDScript).new()
	_check(fresh.fx == 2 and fresh.render_height == 360 and fresh.shadows == 2, "default settings: pixel filter MID, 360p, shadows on all")
	fresh.free()
	_check(story._announced == "" and hud.objective_text() == "", "day 1 starts with no objective: time to look around")
	_check(story._task_timer > 20.0, "day 1 waits %.0f s before Martin thinks about the first task" % story._task_timer)
	story.on_used("fridge")                             # something that is not the objective yet
	await process_frame
	_check(not gs.is_done("rules"), "nothing counts before the task is announced")
	await _wait_announce(story, "rules")
	_check(hud.objective_text() == "Go to the kitchen", "the first objective is '%s'" % hud.objective_text())
	story.on_used("mail")                               # a later task's step does nothing
	await process_frame
	_check(gs.step_index.get("read_letter", 0) == 0 and not gs.is_done("read_letter"), "only the current task accepts steps")
	await _bot_use(story, hud, "fridge")
	_check(gs.is_done("rules"), "Dr. Hale's sheet is read")
	_check(hud.objective_text() == "" and story._task_timer > 20.0, "a quiet stretch follows a task (%.0f s)" % story._task_timer)
	var listed: Array = story._task_list(Days.get_day(1))
	_check(listed.size() == 2, "Martin's list shows what is done and what is next, not the whole day (%d lines)" % listed.size())
	await _wait_announce(story, "read_letter")
	_check(hud.objective_text() == Days.OBJ["mail"], "the letter starts at the mail: '%s'" % hud.objective_text())
	await _bot_use(story, hud, "mail")
	await _wait_announce(story, "lock_up")
	_check(hud.objective_text() == "Check the front door", "locking up is the last thing of the day: '%s'" % hud.objective_text())
	# the notebook opens and lists what he has written down
	var before: int = gs.evidence.size()
	story._notice("door_bed1")
	await process_frame
	_check(gs.evidence.size() == before + 1 and gs.has_evidence("a_door_bed1"), "noticing something writes it in the notebook")
	story._notice("door_bed1")
	_check(gs.evidence.size() == before + 1, "the same thing is written down once")
	story.open_notes()
	await process_frame
	_check(hud.doc_open, "the notes open")
	hud.close_doc()
	# every step of every task has an objective, and every task a thought
	for d in Days.DATA:
		for t in d["tasks"]:
			_check(Days.think_for(t) != "", "task '%s' has a thought" % t["id"])
			for i in (t["steps"] as Array).size():
				_check(Days.objective(t, i) != "", "task '%s' step %d has an objective" % [t["id"], i])
	w.queue_free()
	await process_frame
	Engine.time_scale = 1.0


## Save and load keep the day, tasks, steps, flags, photos and heard messages.
func _save_roundtrip() -> void:
	gs.new_game()
	gs.day = 5
	gs.finish_task("search")
	gs.step_index["photo"] = 1
	gs.set_flag("coat_gone")
	gs.photos = 3
	gs.pending = ["vm2"]
	gs.heard = ["vm1"]
	gs.save()
	gs.new_game()
	_check(gs.day == 1 and gs.photos == 0, "a new game starts clean")
	_check(gs.load_game(), "the save loads")
	_check(gs.day == 5 and gs.is_done("search") and gs.step_index.get("photo", 0) == 1, "day, task and step progress survive a save")
	_check(gs.flag("coat_gone") and gs.photos == 3 and gs.pending == ["vm2"] and gs.heard == ["vm1"], "flags, photos and messages survive a save")
	gs.erase()
	_check(not gs.has_save(), "erasing removes the save")


## A seeded fuzz: random uses of props, random events, photos and menu toggles on random days.
## Nothing may error and the game must stay playable.
func _fuzz() -> void:
	Engine.time_scale = 8.0
	Engine.set_meta("overrides", {"spawn": "door", "no_title": "1"})
	var w = (load("res://scenes/world.tscn") as PackedScene).instantiate()
	root.add_child(w)
	await process_frame
	await process_frame
	var story = w._story
	var apartment = w._apartment
	var hud = w._hud
	var director = w._director
	var stranger = w._stranger
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var ids: Array = apartment.use_points.keys()
	var events: Array = []
	for m in director.get_method_list():
		if (m["name"] as String).begins_with("_ev_"):
			events.append((m["name"] as String).substr(4))
	director.enabled = true
	for round in 6:
		gs.new_game()
		gs.day = rng.randi_range(1, Days.COUNT - 1)
		await story.start_day()
		for i in 70:
			var r := rng.randi() % 10
			if r < 5:
				story.on_used(ids[rng.randi() % ids.size()])
			elif r < 7:
				director.fire(events[rng.randi() % events.size()])
			elif r < 8:
				story.take_photo()
			elif r < 9:
				w._toggle_menu()
				await process_frame
				w._toggle_menu()
			else:
				stranger.vanish()
				gs.play_seconds += rng.randf_range(10.0, 90.0)
				director.update(0.1)
			for k in 3:
				await process_frame
			if hud.doc_open:
				hud.close_doc()
		stranger.vanish()
		story.stop_ring()
		await create_timer(2.0).timeout
	_check(true, "the fuzz ran 420 random actions without an error")
	Engine.time_scale = 1.0
	gs.erase()
	w.queue_free()
	await process_frame
	await process_frame
