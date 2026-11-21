extends SceneTree
## Headless smoke test: run with
##   godot --headless --path game --script res://tests/smoke.gd
## Exits 1 on the first failure. Cannot judge rendering (no GPU), only that
## scripts, scenes, data and collisions are sound.

var _failed := false


func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		_failed = true


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# Film grades and shader
	var shader := load("res://shaders/film_post.gdshader") as Shader
	_check(shader != null, "film shader loads")
	var need := ["sat", "shadow", "high", "contrast", "grain", "vignette"]
	for i in Film.GRADES.size():
		var g: Dictionary = Film.GRADES[i]
		var missing := need.filter(func(k: String) -> bool: return not g.has(k))
		_check(missing.is_empty(), "grade %s has every key %s" % [Film.grade_name(i), missing])

	# Every material builds, and textured ones really have their textures
	for key in Mats.TABLE:
		var m := Mats.get_mat(key)
		var textured: bool = (Mats.TABLE[key] as Dictionary)["tex"] != ""
		_check(m != null and (not textured or (m.albedo_texture != null and m.normal_texture != null)), "material %s" % key)

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

	# The flat
	var flat := Apartment.new()
	root.add_child(flat)
	await process_frame
	await physics_frame
	await physics_frame
	for d in ["bath", "bedroom", "storage", "living", "closet"]:
		_check(flat.doors.has(d), "door %s exists" % d)
	_check(flat.front_door != null, "front door exists")
	for room in ["corridor", "bath", "bedroom", "storage", "living", "closet"]:
		_check(flat.lamps.has(room) and not (flat.lamps[room] as Array).is_empty(), "%s has a lamp" % room)
	var space := root.get_world_3d().direct_space_state
	for room in Apartment.ROOMS:
		var r: Array = Apartment.ROOMS[room]
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3((r[0] + r[1]) * 0.5, 1.5, (r[2] + r[3]) * 0.5), Vector3((r[0] + r[1]) * 0.5, -1.0, (r[2] + r[3]) * 0.5)))
		_check(not hit.is_empty(), "there is a floor in the %s" % room)
	var spots: Dictionary = flat.debug_spots()
	for name in spots:
		var p: Vector3 = spots[name][0]
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3(0, 1.0, 0), p - Vector3(0, 1.0, 0)))
		_check(not hit.is_empty() and absf(hit.position.y) < 0.05, "debug spot '%s' stands on the floor" % name)

	# Lights and switches
	_check(flat.room_lit("corridor"), "corridor lamps start on")
	flat.toggle_room("corridor")
	_check(not flat.room_lit("corridor"), "a switch turns the corridor lamps off")
	flat.toggle_room("corridor")
	flat.apply_shadows(2)
	flat.apply_shadows(0)

	# Doors swing
	for d in ["bedroom", "bath"]:
		var door = flat.doors[d]
		_check(not door.is_open, "%s door starts closed" % d)
		door.interact()
		await create_timer(1.1).timeout
		_check(door.is_open and absf(door.rotation_degrees.y - door.open_angle) < 0.5, "%s door swings open" % d)
		door.interact()
		await create_timer(1.0).timeout
		_check(not door.is_open and absf(door.rotation_degrees.y) < 0.5, "%s door swings closed" % d)
	_check(flat.doors["living"].is_open, "living room doorway starts open")

	await _walk_through(flat)
	flat.queue_free()

	# Settings round-trip
	var s := root.get_node_or_null("Settings")
	_check(s != null, "Settings autoload present")
	if s:
		s.grade = 1
		s.save()
		_check(FileAccess.file_exists("user://settings.cfg"), "settings file written")
		s.grade = 0
		s.save()

	quit(1 if _failed else 0)


## A real CharacterBody3D walks the corridor and through the doors. If a collider blocks
## the way, or a closed door does not block, the check fails.
func _walk_through(flat) -> void:
	var player = (load("res://scripts/player.gd") as GDScript).new()
	root.add_child(player)
	player.position = Vector3(0.0, 0.05, -0.8)
	player.rotation.y = 0.0                                # north, down the corridor
	await _walk(player, Vector2(0, -1), 5.0)
	_check(player.position.z < -9.0 and absf(player.position.x) < 0.6, "walked the corridor to the phone (z=%.1f)" % player.position.z)

	player.position = Vector3(0.0, 0.05, -3.0)
	player.rotation.y = -PI / 2.0                          # east, into the living room (doorway is open)
	await _walk(player, Vector2(0, -1), 2.0)
	_check(player.position.x > 1.6, "walked into the living room (x=%.1f)" % player.position.x)

	player.position = Vector3(0.0, 0.05, -3.5)
	player.rotation.y = PI / 2.0                           # west, at the closed bedroom door
	await _walk(player, Vector2(0, -1), 1.5)
	_check(player.position.x > -0.7, "the closed bedroom door blocks (x=%.2f)" % player.position.x)
	flat.doors["bedroom"].set_open(true, false)
	await _walk(player, Vector2(0, -1), 2.0)
	_check(player.position.x < -1.4, "walked into the bedroom once open (x=%.1f)" % player.position.x)

	player.position = Vector3(0.0, 0.05, -0.8)
	player.rotation.y = PI                                 # south, at the front door
	await _walk(player, Vector2(0, -1), 1.5)
	_check(player.position.z > -0.45 and player.position.z < 0.05, "the front door holds (z=%.2f)" % player.position.z)
	player.queue_free()


func _walk(player, dir: Vector2, seconds: float) -> void:
	player.move_input = dir
	var frames := int(seconds * 60.0)
	for i in frames:
		await physics_frame
	player.move_input = Vector2.ZERO
