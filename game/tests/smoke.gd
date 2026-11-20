extends SceneTree
## Headless smoke test: run with
##   godot --headless --path game --script res://tests/smoke.gd
## Exits 1 on the first failure. Cannot judge rendering (no GPU), only that
## scripts, scenes and data are sound.

var _failed := false


func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		_failed = true


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# Palettes
	_check(Palettes.count() >= 2, "palettes exist")
	for i in Palettes.count():
		var cols := Palettes.colors(i)
		_check(cols.size() >= 2 and cols.size() <= Palettes.MAX_TONES, "palette %s has 2..%d tones" % [Palettes.preset_name(i), Palettes.MAX_TONES])

	# Shader compiles into a material
	var shader := load("res://shaders/dither_palette.gdshader") as Shader
	_check(shader != null, "dither shader loads")

	# Scenes instantiate and survive a few frames
	for path in ["res://scenes/title.tscn", "res://scenes/world.tscn"]:
		var packed := load(path) as PackedScene
		_check(packed != null, "%s loads" % path)
		if packed:
			var inst := packed.instantiate()
			root.add_child(inst)
			await process_frame
			await process_frame
			_check(is_instance_valid(inst), "%s runs two frames" % path)
			inst.queue_free()
			await process_frame

	# Time-of-day presets are complete
	var needed := ["sky", "sky_top", "sky_horizon", "fog", "fog_density", "fog_sky", "ambient", "light_dir", "light_energy", "vignette", "night", "beam", "porch", "sea_base", "sea_glint"]
	for tod in Atmosphere.NAMES:
		var preset: Dictionary = Atmosphere.PRESETS[tod]
		var missing := needed.filter(func(k: String) -> bool: return not preset.has(k))
		_check(missing.is_empty(), "time preset '%s' has every key %s" % [tod, missing])

	# Island terrain
	var island = (load("res://scripts/island.gd") as GDScript).new()   # runtime load: autoloads are not visible while compiling this file
	root.add_child(island)
	await process_frame
	_check(absf(island.height_at(0.0, -20.0) - island.PLATEAU) < 4.0, "island top is about plateau height")
	_check(island.height_at(0.0, 60.0) < 0.0 and island.height_at(-60.0, 0.0) < 0.0, "sea around the island")
	_check(island.spawn_point().y > 0.0, "spawn is above the sea")
	var prev: float = island.height_at(0.0, 8.0)
	var steepest := 0.0
	var z := 9.0
	while z <= 30.0:
		var h: float = island.height_at(0.0, z)
		steepest = maxf(steepest, absf(h - prev))
		if h > prev + 0.001:
			_check(false, "ramp descends monotonically at z=%d" % int(z))
		prev = h
		z += 1.0
	_check(steepest < 0.85, "ramp is walkable (max %.2f m rise per metre)" % steepest)
	_check(absf(island.height_at(island.HUT_CENTER.x, island.HUT_CENTER.y) - (island.PLATEAU - 0.08)) < 0.02, "hut pad is level")
	island.queue_free()

	# Door animation
	var room = (load("res://scripts/store_room.gd") as GDScript).new()
	root.add_child(room)
	await process_frame
	_check(room.door != null and not room.door.is_open, "door exists and starts closed")
	room.door.interact()
	await create_timer(1.1).timeout
	_check(room.door.is_open and absf(room.door.rotation_degrees.y - room.door.open_angle) < 0.5, "door swings open")
	room.door.interact()
	await create_timer(1.0).timeout
	_check(not room.door.is_open and absf(room.door.rotation_degrees.y) < 0.5, "door swings closed")
	var catch_found := false
	for c in room.get_children():
		if c is DoorCatch:
			catch_found = c.door == room.door and c.prompt == room.door.prompt
	_check(catch_found, "doorway has an interaction catch that follows the door's prompt")
	room.queue_free()

	# Settings round-trip
	var s := root.get_node_or_null("Settings")
	_check(s != null, "Settings autoload present")
	if s:
		s.palette = 2
		s.save()
		_check(FileAccess.file_exists("user://settings.cfg"), "settings file written")
		s.palette = 0
		s.save()

	quit(1 if _failed else 0)
