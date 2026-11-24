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
	var atmosphere = load("res://scripts/atmosphere.gd")   # runtime load: it refers to StoreRoom, which needs the Settings autoload
	for tod in atmosphere.NAMES:
		var preset: Dictionary = atmosphere.PRESETS[tod]
		var missing := needed.filter(func(k: String) -> bool: return not preset.has(k))
		_check(missing.is_empty(), "time preset '%s' has every key %s" % [tod, missing])

	# Island: the approach from the quay is gentle, and the terrain really collides
	var island = (load("res://scripts/island.gd") as GDScript).new()   # runtime load: autoloads are not visible while compiling this file
	root.add_child(island)
	await process_frame
	await physics_frame
	await physics_frame
	var path: Array = island.path_points()
	_check(path.size() >= 10, "approach path has %d points" % path.size())
	var worst := 0.0
	for i in range(1, path.size()):
		var pa: Vector3 = path[i - 1]
		var pb: Vector3 = path[i]
		var run := Vector2(pb.x - pa.x, pb.z - pa.z).length()
		if run > 0.5:
			worst = maxf(worst, absf(pb.y - pa.y) / run)
	_check(worst < tan(deg_to_rad(10.0)), "approach stays under 10 degrees (worst %.1f)" % rad_to_deg(atan(worst)))
	var space := root.get_world_3d().direct_space_state
	for k in [0, path.size() / 2, path.size() - 1]:
		var pp: Vector3 = path[k]
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(pp + Vector3(0, 8, 0), pp - Vector3(0, 8, 0)))
		_check(not hit.is_empty() and absf(hit.position.y - pp.y) < 1.2, "terrain collides under path point %d" % k)
	_check(island.spawn_point().y > 0.5, "spawn is above the sea")
	var sp: Vector3 = island.spawn_point()
	var spawn_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(sp + Vector3(0, 2, 0), sp - Vector3(0, 4, 0)))
	_check(not spawn_hit.is_empty(), "there is a floor under the spawn point")
	island.queue_free()

	# Lighthouse: doors, stairs and the underground store
	var lh = (load("res://scripts/lighthouse.gd") as GDScript).new()
	root.add_child(lh)
	await process_frame
	await physics_frame
	await physics_frame
	_check(lh.entrance_door != null and lh.stair_door != null, "entrance and stair doors exist")
	_check(lh.store != null and lh.store.door != null, "underground store and its door exist")
	var lspace := root.get_world_3d().direct_space_state
	var step_hit := lspace.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-4.1, -0.3, 7.0), Vector3(-4.1, -4.5, 7.0)))
	_check(not step_hit.is_empty() and step_hit.position.y < -1.2 and step_hit.position.y > -2.2, "stairs have a floor part-way down")
	var store_hit := lspace.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-2.5, -1.0, 12.3), Vector3(-2.5, -4.5, 12.3)))
	_check(not store_hit.is_empty() and absf(store_hit.position.y - lh.STORE_FLOOR_Y) < 0.1, "the store floor is where the stairs end")
	for door_name in ["entrance_door", "stair_door"]:
		var d = lh.get(door_name)
		_check(not d.is_open, "%s starts closed" % door_name)
		d.interact()
		await create_timer(1.1).timeout
		_check(d.is_open and absf(d.rotation_degrees.y - d.open_angle) < 0.5, "%s swings open" % door_name)
		d.interact()
		await create_timer(1.0).timeout
		_check(not d.is_open and absf(d.rotation_degrees.y) < 0.5, "%s swings closed" % door_name)
	await _walk_through(lh)
	var catch_found := false
	for c in lh.get_children():
		if c is DoorCatch:
			catch_found = c.door == lh.entrance_door and c.prompt == lh.entrance_door.prompt
	_check(catch_found, "entrance has an interaction catch that follows the door's prompt")
	lh.queue_free()

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


## A real CharacterBody3D walks from outside the entrance, through the hall, the
## stair door, down the stairs and through the store door. If any collider blocks the
## way (or a door has no gap) it stops short and the check fails.
func _walk_through(lh) -> void:
	var yard := StaticBody3D.new()                       # ground outside (the island is not loaded in this test)
	var ys := CollisionShape3D.new()
	var yb := BoxShape3D.new()
	yb.size = Vector3(40, 1, 32)
	ys.shape = yb
	yard.add_child(ys)
	yard.position = Vector3(0, -0.5, 25.0)            # outside ground, z 9..41 (the real game has terrain here)
	root.add_child(yard)

	lh.entrance_door.set_open(true, false)
	lh.stair_door.set_open(true, false)
	lh.store.door.set_open(true, false)
	var player = (load("res://scripts/player.gd") as GDScript).new()
	root.add_child(player)
	player.position = Vector3(0.0, 0.05, 11.5)
	player.rotation.y = 0.0                              # facing north (-Z)

	await _walk(player, Vector2(0, -1), 3.2)             # through the entrance into the hall
	_check(player.position.z < 8.0 and player.position.z > 4.0, "walked in through the entrance (z=%.1f)" % player.position.z)
	player.rotation.y = PI / 2.0                         # face west: toward the stair door in the partition
	player.position.z = 4.0
	player.position.x = 0.0
	await _walk(player, Vector2(0, -1), 3.0)
	_check(player.position.x < -3.6, "walked through the stair door (x=%.1f)" % player.position.x)
	player.rotation.y = PI                               # face south, down the stairs
	player.position.x = -4.1
	player.position.z = 4.2
	await _walk(player, Vector2(0, -1), 4.5)
	_check(player.position.y < -2.8, "walked down the stairs (y=%.1f)" % player.position.y)
	await _walk(player, Vector2(0, -1), 3.0)
	_check(player.position.z > 10.5 and player.position.y < -3.0, "reached the store through its door (z=%.1f, y=%.1f)" % [player.position.z, player.position.y])
	player.queue_free()
	yard.queue_free()


func _walk(player, dir: Vector2, seconds: float) -> void:
	player.move_input = dir
	var frames := int(seconds * 60.0)
	for i in frames:
		await physics_frame
	player.move_input = Vector2.ZERO
