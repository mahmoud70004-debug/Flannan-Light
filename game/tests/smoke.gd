extends SceneTree
## Headless smoke test: run with
##   godot --headless --path game --script res://tests/smoke.gd
## Exits 1 on the first failure. Cannot judge rendering (no GPU), only that scripts, scenes,
## data and collisions are sound. The flat is checked as data: every door and arch is walked
## through in both directions by a real CharacterBody3D, every spawn spot must be free of
## geometry, and the entrance must not see down the whole hall.

var _failed := false


func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		_failed = true


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
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

	# The flat, as data
	var flat := Apartment.new()
	root.add_child(flat)
	await process_frame
	await physics_frame
	await physics_frame
	var space := root.get_world_3d().direct_space_state

	for name in Apartment.CELLS:
		var r: Array = Apartment.CELLS[name]["r"]
		var w: float = r[1] - r[0]
		var d: float = r[3] - r[2]
		if not name.begins_with("hall"):
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
	var cap := CapsuleShape3D.new()
	cap.radius = 0.27
	cap.height = 1.7
	for name in spots:
		var p: Vector3 = spots[name][0]
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = cap
		q.transform = Transform3D(Basis(), p + Vector3(0, 0.88, 0))
		q.collision_mask = 1
		var floor_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3(0, 0.5, 0), p - Vector3(0, 1.0, 0)))
		_check(space.intersect_shape(q, 1).is_empty() and not floor_hit.is_empty(), "spot '%s' is free and on the floor" % name)

	# The entrance must not show the whole flat: the hall door starts closed and blocks the line to the phone
	var eye := flat.spawn_point() + Vector3(0, 1.6, 0)
	var target := Vector3(-0.3, 1.0, -9.6)
	var sight := space.intersect_ray(PhysicsRayQueryParameters3D.create(eye, target))
	_check(not sight.is_empty() and sight.position.z > -5.0, "from the front door the phone is hidden behind the hall door")

	# Lights and switches
	_check(flat.room_lit("hall_front"), "hall lamps start on")
	flat.toggle_room("hall_front")
	_check(not flat.room_lit("hall_front"), "a switch turns the hall lamps off")
	flat.toggle_room("hall_front")
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

	# Only rooms the player can see through open openings are drawn
	var viewer := Node3D.new()
	root.add_child(viewer)
	viewer.global_position = flat.spawn_point()
	flat.viewer = viewer
	await process_frame
	await process_frame
	var vis: Array = flat.visible_cells("hall_front")
	_check(vis == ["hall_front"], "with every door closed only the front hall is visible %s" % [vis])
	flat.doors["hall"].set_open(true, false)
	vis = flat.visible_cells("hall_front")
	_check("hall_back" in vis and "hall_w" in vis and not ("bath" in vis), "an open hall door shows the back hall and its leg %s" % [vis])
	await process_frame
	await process_frame
	var hidden_bath := true
	for n in flat.cull_items:
		if n.layers == Apartment.L_BATH and n.visible:
			hidden_bath = false
	_check(hidden_bath, "bathroom meshes are hidden from the front hall")
	flat.doors["hall"].set_open(false, false)
	flat.viewer = null
	viewer.queue_free()

	await _walk_openings(flat)
	flat.queue_free()

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
			(flat.doors[t[0]] as Door).set_open(true, false)
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
			(flat.doors[t[0]] as Door).set_open(false, false)

	# The front door holds
	player.position = Vector3(-0.3, 0.05, -0.8)
	player.rotation.y = PI
	await _walk(player, Vector2(0, -1), 1.5)
	_check(player.position.z > -0.5 and player.position.z < 0.05, "the front door holds (z=%.2f)" % player.position.z)

	# A closed door blocks
	player.position = Vector3(-0.3, 0.05, -2.2)
	player.rotation.y = PI / 2.0                      # west, at the closed bath door? (z=-1.2): walk the hall instead
	player.rotation.y = atan2(0.0, 1.0)               # north along the hall
	await _walk(player, Vector2(0, -1), 2.0)
	_check(player.position.z > -4.6, "the closed hall door blocks (z=%.2f)" % player.position.z)
	player.queue_free()


func _walk(player, dir: Vector2, seconds: float) -> void:
	player.move_input = dir
	var frames := int(seconds * 60.0)
	for i in frames:
		await physics_frame
	player.move_input = Vector2.ZERO
