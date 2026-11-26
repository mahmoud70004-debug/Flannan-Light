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

	# Island: the dock and the cliff stair, walked by a real body, pushed sideways, and timed
	var island = (load("res://scripts/island.gd") as GDScript).new()   # runtime load: autoloads are not visible while compiling this file
	root.add_child(island)
	await process_frame
	await physics_frame
	await physics_frame
	var walk: Array = island.walk_points()
	_check(walk.size() >= 7, "the walk has %d points (dock end, stair foot, flights, landings)" % walk.size())
	var steepest := 0.0
	for i in range(1, walk.size()):
		var pa: Vector3 = walk[i - 1]
		var pb: Vector3 = walk[i]
		steepest = maxf(steepest, rad_to_deg(atan(absf(pb.y - pa.y) / Vector2(pb.x - pa.x, pb.z - pa.z).length())))
	_check(steepest < 35.0, "no flight steeper than 35 degrees (steepest %.1f)" % steepest)
	var space := root.get_world_3d().direct_space_state
	for k in walk.size():
		var pp: Vector3 = walk[k]
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(pp + Vector3(0, 0.8, 0), pp - Vector3(0, 2, 0)))
		_check(not hit.is_empty() and absf(hit.position.y - pp.y) < 0.12, "walking surface under walk point %d" % k)
	var sp: Vector3 = island.spawn_point()
	var spawn_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(sp + Vector3(0, 2, 0), sp - Vector3(0, 4, 0)))
	_check(not spawn_hit.is_empty() and spawn_hit.position.y > 0.5, "the spawn stands on the dock above the sea")
	await _island_walks(island)
	island.queue_free()

	# Lighthouse: doors, the spiral stair, the lantern room and gallery, the store underground, the bedroom
	var lh = (load("res://scripts/lighthouse.gd") as GDScript).new()
	root.add_child(lh)
	await process_frame
	await physics_frame
	await physics_frame
	_check(lh.entrance_door != null and lh.stair_door != null and lh.bedroom_door != null, "entrance, oil-store and bedroom doors exist")
	_check(lh.store != null and lh.store.door != null, "underground store and its door exist")
	var lspace := root.get_world_3d().direct_space_state
	var mid_t := 500.0
	var mp: Vector3 = MeshBuilder.polar(lh.stair_angle(mid_t), 2.25, lh.stair_y(mid_t))
	var step_hit := lspace.intersect_ray(PhysicsRayQueryParameters3D.create(mp + Vector3(0, 1.0, 0), mp - Vector3(0, 3.0, 0)))
	_check(not step_hit.is_empty() and absf(step_hit.position.y - mp.y) < 0.1, "the spiral has a floor half way up")
	var store_hit := lspace.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(lh.SHED_STAIR_X, -1.0, lh.STORE_FRONT_Z - 0.7), Vector3(lh.SHED_STAIR_X, -4.5, lh.STORE_FRONT_Z - 0.7)))
	_check(not store_hit.is_empty() and absf(store_hit.position.y - lh.STORE_FLOOR_Y) < 0.1, "the store floor is where the oil-store stair ends")
	for door_name in ["entrance_door", "stair_door", "bedroom_door"]:
		var d = lh.get(door_name)
		_check(not d.is_open, "%s starts closed" % door_name)
		d.interact()
		await create_timer(1.1).timeout
		_check(d.is_open and absf(d.rotation_degrees.y - d.open_angle) < 0.5, "%s swings open" % door_name)
		d.interact()
		await create_timer(1.0).timeout
		_check(not d.is_open and absf(d.rotation_degrees.y) < 0.5, "%s swings closed" % door_name)
	await _tower_walks(lh)
	var catch_found := false
	for c in lh.find_children("*", "DoorCatch", true, false):
		if c.door == lh.entrance_door:
			catch_found = c.prompt == lh.entrance_door.prompt
	_check(catch_found, "entrance has an interaction catch that follows the door's prompt")
	lh.queue_free()

	# Old saved settings (an earlier build at 240p, brighter) give way to the new defaults
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", 3)
	cfg.set_value("video", "render_height", 240)
	cfg.set_value("video", "brightness", 1.6)
	cfg.save("user://settings.cfg")
	var fresh = (load("res://scripts/settings.gd") as GDScript).new()
	fresh._ready()
	_check(fresh.render_height == 360 and absf(fresh.brightness - 1.15) < 0.01, "old saved settings are replaced by the new defaults (%dp, brightness %.2f)" % [fresh.render_height, fresh.brightness])
	fresh.free()

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


## Steers a body through targets (by x and z). Returns [reached, seconds, where it stalled].
func _steer(player, targets: Array, tol := 0.5, max_frames := 900) -> Array:
	var frames := 0
	for target in targets:
		var tries := 0
		while Vector2(player.position.x - target.x, player.position.z - target.z).length() > tol:
			if tries >= max_frames:
				player.move_input = Vector2.ZERO
				return [false, frames / 60.0, target]
			var d: Vector3 = target - player.position
			player.rotation.y = atan2(-d.x, -d.z)
			player.move_input = Vector2(0, -1)
			await physics_frame
			tries += 1
			frames += 1
	player.move_input = Vector2.ZERO
	return [true, frames / 60.0, null]


## Pushes a body one way for a while (strafing: the body faces `face`, input pushes along `push`).
func _push(player, push: Vector3, seconds: float) -> void:
	player.rotation.y = atan2(-push.x, -push.z)
	player.move_input = Vector2(0, -1)
	for i in int(seconds * 60.0):
		await physics_frame
	player.move_input = Vector2.ZERO
	for i in 6:
		await physics_frame


func _new_player(pos: Vector3):
	var player = (load("res://scripts/player.gd") as GDScript).new()
	root.add_child(player)
	player.position = pos
	await physics_frame
	return player


## The dock and the stair: walk up and down; at the middle of every segment and at every turn, shove the body
## against each rail for two seconds: it must stay on the walk. Walking times are printed (long walks bore).
func _island_walks(island) -> void:
	var walk: Array = island.walk_points()
	var player = await _new_player(island.spawn_point())
	var up: Array = await _steer(player, walk.slice(1))
	_check(up[0], "walked from the dock up the stair to the cliff-top (stalled near %s)" % [up[2]])
	print("INFO  dock end to the top of the stair: %.0f s" % up[1])
	var down: Array = await _steer(player, _reversed(walk.slice(0, walk.size() - 1)))
	_check(down[0], "walked back down to the end of the dock (stalled near %s)" % [down[2]])
	print("INFO  top of the stair back to the dock end: %.0f s" % down[1])
	var w: float = island.WALK_W
	var escaped := 0
	var probes := 0
	for i in walk.size() - 1:
		for f in [0.08, 0.5]:
			var a: Vector3 = walk[i]
			var b: Vector3 = walk[i + 1]
			var c := a.lerp(b, f)
			var d := Vector3(b.x - a.x, 0, b.z - a.z).normalized()
			for side in [Vector3(-d.z, 0, d.x), Vector3(d.z, 0, -d.x)]:
				player.position = c + Vector3(0, 0.15, 0)
				player.velocity = Vector3.ZERO
				await physics_frame
				await _push(player, side, 2.0)
				var on := _on_walk(walk, player.position, w)
				probes += 1
				if not on:
					escaped += 1
					print("      escaped at segment %d (f=%.2f): at %s" % [i, f, player.position])
	_check(escaped == 0, "pushed against the rails %d times: never got off the walk (%d escapes)" % [probes, escaped])
	# Walk off the cliff-top in sixteen directions. Wherever you end up you must be able to walk back to the tower
	# door, or be in the sea (where the game puts you back on safe ground). Nowhere may strand you.
	var tower: Vector3 = island.lighthouse_position()
	var door: Vector3 = island.door_point()
	var stranded := 0
	for k in 16:
		var dir := Vector3(sin(k * TAU / 16.0), 0, cos(k * TAU / 16.0))
		player.position = tower + dir * 5.0 + Vector3(0, 0.3, 0)
		player.velocity = Vector3.ZERO
		await physics_frame
		await _push(player, dir, 12.0)
		var end: Vector3 = player.position
		var fine: bool = end.y < Island.SEA_Y + 0.1 or island.on_walk(end)
		if not fine:
			var back: Array = await _steer(player, [door], 1.0, 1500)
			fine = back[0] or player.position.y < Island.SEA_Y + 0.1
		if not fine:
			stranded += 1
			print("      stranded walking off toward %d: ended at %s, stuck at %s" % [k, end, player.position])
	_check(stranded == 0, "walking off the cliff-top never strands you (%d of 16 directions did)" % stranded)
	player.position = walk[0] - island.seaward() * 1.0 + Vector3(0, 0.15, 0)
	await physics_frame
	await _push(player, island.seaward(), 2.0)
	_check(player.position.y > walk[0].y - 0.3, "the end of the dock is closed: you cannot walk off into the sea")
	player.queue_free()


## Is a position on the walk: within half its width of the centre line (in plan) and near its surface height?
func _on_walk(walk: Array, p: Vector3, w: float) -> bool:
	for i in walk.size() - 1:
		var a: Vector3 = walk[i]
		var b: Vector3 = walk[i + 1]
		var ab := Vector2(b.x - a.x, b.z - a.z)
		var t := clampf(Vector2(p.x - a.x, p.z - a.z).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var q := a.lerp(b, t)
		if Vector2(p.x - q.x, p.z - q.z).length() <= w / 2.0 + 0.4 and absf(p.y - q.y) < 0.5:
			return true
	return false


func _reversed(a: Array) -> Array:
	var r := a.duplicate()
	r.reverse()
	return r


## Inside the tower: walk in, up the spiral to the lantern room, out on the gallery, back down; down to the store and
## back; into the bedroom. Shove the body off the stair's open side and the gallery's edge: it must stay put.
func _tower_walks(lh) -> void:
	var yard := StaticBody3D.new()                       # the ground in front of the door (the island is not loaded)
	var ys := CollisionShape3D.new()
	var yb := BoxShape3D.new()
	yb.size = Vector3(40, 1, 18)
	ys.shape = yb
	yard.add_child(ys)
	yard.position = Vector3(0, -0.5, 12.0)
	root.add_child(yard)
	lh.entrance_door.set_open(true, false)
	lh.stair_door.set_open(true, false)
	lh.bedroom_door.set_open(true, false)
	lh.store.door.set_open(true, false)
	var player = await _new_player(Vector3(0, 0.1, 7.0))
	var r: Array = await _steer(player, [Vector3(0, 0, 1.2)])
	_check(r[0] and player.position.z < 2.0, "walked in through the entrance")
	# up the spiral
	var line: Array = [MeshBuilder.polar(-4.0, 2.25, 0.0)]
	var t := 0.0
	while t <= 1080.0:
		line.append(MeshBuilder.polar(lh.stair_angle(t), 2.25, lh.stair_y(t)))
		t += 15.0
	line.append(MeshBuilder.polar(lh.stair_angle(1080.0) - 30.0, 2.2, lh.TOP_Y))
	r = await _steer(player, line, 0.45)
	_check(r[0] and player.position.y > lh.TOP_Y - 0.3, "climbed the spiral to the lantern room (y=%.1f, stalled near %s)" % [player.position.y, r[2]])
	print("INFO  climbing the spiral stair: %.0f s" % r[1])
	r = await _steer(player, [MeshBuilder.polar(-90.0, 2.2, 0.0), MeshBuilder.polar(-90.0, 3.5, 0.0)], 0.35)
	_check(r[0] and absf(player.position.y - lh.TOP_Y) < 0.3, "walked out through the lantern door onto the gallery")
	var fell := 0
	for a in [-90.0, -30.0, 60.0, 150.0, -150.0]:
		player.position = MeshBuilder.polar(a, 3.5, lh.TOP_Y + 0.1)
		player.velocity = Vector3.ZERO
		await physics_frame
		await _push(player, MeshBuilder.radial(a), 2.0)
		var rr := Vector2(player.position.x, player.position.z).length()
		if rr > lh.RAIL_R or player.position.y < lh.TOP_Y - 0.3:
			fell += 1
	_check(fell == 0, "the gallery railing holds all the way round (%d escapes)" % fell)
	# shove off the open side of the stair, and into the hole round the top of it
	var slipped := 0
	for tt in [60.0, 200.0, 420.0, 640.0, 900.0, 1040.0]:
		var p: Vector3 = MeshBuilder.polar(lh.stair_angle(tt), 2.25, lh.stair_y(tt) + 0.15)
		player.position = p
		player.velocity = Vector3.ZERO
		await physics_frame
		await _push(player, -MeshBuilder.radial(lh.stair_angle(tt)), 2.0)
		if player.position.y < p.y - 0.6:
			slipped += 1
			print("      fell off the spiral at t=%d: y %.2f -> %.2f" % [tt, p.y, player.position.y])
	for a in [70.0, 100.0, 130.0]:
		player.position = MeshBuilder.polar(a, 1.1, lh.TOP_Y + 0.1)
		player.velocity = Vector3.ZERO
		await physics_frame
		await _push(player, MeshBuilder.radial(a), 2.0)
		if player.position.y < lh.TOP_Y - 0.3:
			slipped += 1
			print("      fell into the stair hole at %d" % a)
	_check(slipped == 0, "cannot fall off the spiral or into the hole round its top (%d falls)" % slipped)
	# back down
	player.position = MeshBuilder.polar(-90.0, 2.2, lh.TOP_Y + 0.1)
	await physics_frame
	var back := _reversed(line)                          # off the foot of the stair, then into the room
	back.append(Vector3(0.4, 0, 2.0))
	back.append(Vector3(0, 0, 0.8))
	r = await _steer(player, back, 0.45)
	_check(r[0] and player.position.y < 0.4, "came back down the spiral to the ground floor (y=%.1f, stalled near %s at %s)" % [player.position.y, r[2], player.position])
	print("INFO  coming down the spiral stair: %.0f s" % r[1])
	# the oil store and the stair down to the store
	var sx: float = lh.SHED_STAIR_X
	var store_path := [Vector3(1.5, 0, 0), Vector3(3.3, 0, 0), Vector3(sx, 0, -0.1), Vector3(sx, 0, lh.SHED_STAIR_BOTTOM_Z - 0.3),
			Vector3(sx, 0, lh.STORE_FRONT_Z - 1.3)]
	r = await _steer(player, store_path, 0.35)
	_check(r[0] and absf(player.position.y - lh.STORE_FLOOR_Y) < 0.3, "went through the oil-store door and down into the store (y=%.1f, stalled near %s)" % [player.position.y, r[2]])
	print("INFO  ground floor to the store: %.0f s" % r[1])
	r = await _steer(player, [Vector3(sx, 0, lh.SHED_STAIR_BOTTOM_Z - 0.3), Vector3(sx, 0, -0.1), Vector3(3.3, 0, 0), Vector3(0.5, 0, 0)], 0.35)
	_check(r[0] and player.position.y > -0.2, "came back up from the store into the tower")
	r = await _steer(player, [Vector3(0, 0, -1.5), Vector3(0, 0, -3.4), Vector3(-0.2, 0, -4.4)], 0.35)
	_check(r[0] and player.position.z < -4.0, "walked through the back door into the bedroom")
	player.queue_free()
	yard.queue_free()


func _walk(player, dir: Vector2, seconds: float) -> void:
	player.move_input = dir
	var frames := int(seconds * 60.0)
	for i in frames:
		await physics_frame
	player.move_input = Vector2.ZERO
