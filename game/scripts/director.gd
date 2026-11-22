class_name Director
extends Node
## The psychological-horror director. It schedules small wrong things inside Martin's ordinary day:
## sounds from rooms he is not in, doors that open by themselves, lights that flicker and go out, a
## phone that rings, a TV that wakes up with static, and the stranger standing where it was not a
## second ago. Rules (see docs/features/hallucination-director):
##   * Nothing hurts Martin or blocks him. A scare is a sound, a light or a figure.
##   * The stranger only appears unseen, holds still while watched, and is gone when stared at.
##   * A cooldown separates events and a quiet spell follows every blackout.
##   * What can happen, and how often, is data in Days (per day), not code here.

signal event_fired(name: String)

var apartment: Apartment
var player: Player
var stranger: Stranger
var story: Story
var enabled := true
var rng := RandomNumberGenerator.new()

var _next_in := 30.0
var _busy := false
var _quiet := 0.0
var _scripted: Array = []          ## [{at, do, fired}] for the current day
var _recent: Array = []
var _last_name := ""


func _ready() -> void:
	rng.randomize()


## Called at the start of every day with that day's data.
func start_day(data: Dictionary) -> void:
	_scripted = []
	for s in data.get("scripted", []):
		_scripted.append({"at": s["at"], "do": s["do"], "fired": false})
	var ev: Dictionary = data.get("events", {})
	_next_in = float(ev.get("first", 40.0))
	_quiet = 0.0
	_recent = []


func update(delta: float) -> void:
	if not enabled or story == null or not story.is_free():
		return
	_quiet = maxf(_quiet - delta, 0.0)
	if _busy or _quiet > 0.0:
		return
	var t := GameState.play_seconds
	for s in _scripted:
		if not s["fired"] and t >= s["at"]:
			s["fired"] = true
			fire(s["do"])
			return
	_next_in -= delta
	if _next_in > 0.0:
		return
	var data := Days.get_day(GameState.day)
	var ev: Dictionary = data.get("events", {})
	var pool: Array = (ev.get("pool", []) as Array).duplicate()
	pool = pool.filter(func(n: String) -> bool: return not (n in _recent))
	if pool.is_empty():
		pool = (ev.get("pool", []) as Array).duplicate()
	if pool.is_empty():
		_next_in = 60.0
		return
	var every: Array = ev.get("every", [60.0, 90.0])
	_next_in = rng.randf_range(every[0], every[1])
	fire(pool[rng.randi() % pool.size()])


## Runs an event by name (also used for scripted moments and by tests).
func fire(event_name: String) -> void:
	_recent.append(event_name)
	if _recent.size() > 2:
		_recent.pop_front()
	_last_name = event_name
	event_fired.emit(event_name)
	var m := "_ev_" + event_name
	if has_method(m):
		_busy = true
		await call(m)
		_busy = false


# --- helpers -----------------------------------------------------------------------------------------

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _pcell() -> String:
	return apartment.cell_at(player.global_position)


func _eye() -> Vector3:
	return player.camera.global_position


func _behind(dist: float) -> Vector3:
	var back := player.global_transform.basis * Vector3(0, 0, dist)
	return Vector3(player.global_position.x + back.x, 1.5, player.global_position.z + back.z)


## The centre of a random room the player is not in, at least `min_d` metres away.
func _far_room_pos(min_d: float) -> Vector3:
	var cells: Array = apartment.CELLS.keys()
	cells.shuffle()
	for c in cells:
		if c == _pcell():
			continue
		var r: Array = apartment.rect_of(c)
		var p := Vector3((r[0] + r[1]) * 0.5, 1.3, (r[2] + r[3]) * 0.5)
		if Vector2(p.x - player.global_position.x, p.z - player.global_position.z).length() >= min_d:
			return p
	return Vector3(0.1, 1.3, -1.0)


func _closed_doors_away() -> Array:
	var out: Array = []
	for n in apartment.doors:
		var d: Door = apartment.doors[n]
		if d.is_open:
			continue
		var info: Dictionary = apartment.door_info[n]
		var c: Vector3 = info["center"]
		if Vector2(c.x - player.global_position.x, c.z - player.global_position.z).length() > 3.0:
			out.append(n)
	return out


func _door_pos(n: String) -> Vector3:
	return (apartment.door_info[n]["center"] as Vector3) + Vector3(0, 1.1, 0)


func _fear(amount: float) -> void:
	if story:
		story.boost_fear(amount)


# --- events ---------------------------------------------------------------------------------------------

func _ev_cough() -> void:
	Sfx.play_at("cough_%d" % rng.randi_range(0, 1), _far_room_pos(5.0), -3.0, 16.0, 3.0)
	_fear(0.06)
	await _wait(1.5)


func _ev_footsteps() -> void:
	var start := _far_room_pos(6.0)
	var p := player.global_position
	var dir := Vector3(p.x - start.x, 0, p.z - start.z)
	var end := start + dir.normalized() * maxf(dir.length() - 3.6, 1.0)
	var n := 7
	for i in n:
		var pos := start.lerp(end, float(i) / float(n - 1))
		pos.y = 0.1
		Sfx.play_at("step_%d" % rng.randi_range(0, 3), pos, -2.0, 14.0, 2.5)
		await _wait(rng.randf_range(0.5, 0.68))
	_fear(0.1)
	story.ambience.hush(4.0, 0.6) if story and story.ambience else null
	await _wait(3.0)


func _ev_footsteps_door() -> void:                 # a night event: someone at the bedroom door
	await _ev_footsteps()


func _ev_knock() -> void:
	Sfx.play_at("knock3", Vector3(0.1, 1.3, -0.15), 0.0, 18.0, 4.0)
	_fear(0.12)
	await _wait(2.0)


func _ev_knock_front() -> void:
	await _ev_knock()


func _ev_knock_door() -> void:
	var doors := _closed_doors_away()
	if doors.is_empty():
		await _ev_knock()
		return
	Sfx.play_at("knock3", _door_pos(doors[rng.randi() % doors.size()]), 0.0, 14.0, 3.0)
	_fear(0.12)
	await _wait(2.0)


func _ev_door_creak() -> void:
	var doors := _closed_doors_away()
	if doors.is_empty():
		return
	var n: String = doors[rng.randi() % doors.size()]
	Sfx.play_at("door_creak", _door_pos(n), -2.0, 12.0, 2.5)
	(apartment.doors[n] as Door).set_open(true)
	_fear(0.1)
	await _wait(2.5)


func _ev_door_open() -> void:
	await _ev_door_creak()


func _ev_lights_flicker() -> void:
	var cell := _pcell()
	if cell == "":
		return
	Sfx.play_at("lamp_buzz", player.global_position + Vector3(0, 2.0, 0), -4.0, 8.0, 2.0)
	for i in 6:
		apartment.set_room_lit(cell, false)
		await _wait(rng.randf_range(0.05, 0.16))
		apartment.set_room_lit(cell, true)
		await _wait(rng.randf_range(0.07, 0.22))
	_fear(0.1)
	await _wait(1.0)


func _ev_lights_out() -> void:
	var cell := _pcell()
	if cell == "":
		return
	var lit_before: Array = []
	for c in apartment.lamps:
		if apartment.room_lit(c) and (c == cell or c.begins_with(cell)):
			lit_before.append(c)
	Sfx.play_at("lamp_buzz", player.global_position + Vector3(0, 2.0, 0), -2.0, 8.0, 2.0)
	for c in lit_before:
		apartment.set_room_lit(c, false)
	if story:
		story.ambience.hush(8.0, 0.7)
	_fear(0.25)
	await _wait(1.8)
	Sfx.play_at("breath", _behind(1.0), -5.0, 6.0, 1.0)
	if GameState.day >= 4 and rng.randf() < 0.8:
		_spawn_stranger(4.0, 9.0)
	await _wait(rng.randf_range(4.0, 6.0))
	for i in 3:                                     # the lights come back unsteadily
		for c in lit_before:
			apartment.set_room_lit(c, i % 2 == 1)
		await _wait(rng.randf_range(0.08, 0.2))
	for c in lit_before:
		apartment.set_room_lit(c, true)
	_quiet = 30.0                                   # a breather after a blackout
	await _wait(0.5)


func _ev_phone_ring() -> void:
	story.start_ring()
	await _wait(1.0)


func _ev_whisper() -> void:
	Sfx.play_at("whisper_%d" % rng.randi_range(0, 4), _behind(1.4), -2.0, 6.0, 1.0)
	_fear(0.15)
	await _wait(3.0)


func _ev_whisper_bed() -> void:
	await _ev_whisper()


func _ev_laugh() -> void:
	Sfx.play_at("laugh_%d" % rng.randi_range(0, 1), _far_room_pos(6.0), -3.0, 16.0, 3.0)
	_fear(0.15)
	await _wait(3.0)


func _ev_breath() -> void:
	Sfx.play_at("breath", _behind(0.9), -3.0, 5.0, 1.0)
	_fear(0.1)
	await _wait(3.0)


func _ev_tv_static() -> void:
	var tv: Vector3 = apartment.tv_position()
	apartment.set_tv(true)
	var p := Sfx.play_at("tv_static", tv, -3.0, 12.0, 2.0)
	_fear(0.2)
	for i in 50:
		apartment.set_tv_level(rng.randf_range(0.2, 1.0))
		await _wait(0.12)
	apartment.set_tv(false)
	if p:
		p.stop()
	Sfx.play_at("whisper_0", tv + Vector3(0, 0, 1.0), -4.0, 8.0, 1.0)
	await _wait(2.0)


func _ev_stranger_far() -> void:
	_spawn_stranger(6.0, 11.0)
	await _wait(2.0)


func _ev_stranger_near() -> void:
	_spawn_stranger(3.2, 6.0)
	await _wait(2.0)


func _ev_stranger_hall() -> void:
	_spawn_stranger(5.0, 12.0)
	await _wait(2.0)


## Puts the stranger somewhere the player cannot currently see, `min_d`..`max_d` metres away, with a clear line to it.
func _spawn_stranger(min_d: float, max_d: float) -> bool:
	if stranger.state != Stranger.State.HIDDEN:
		return false
	var spots: Array = apartment.stranger_spots.duplicate()
	spots.shuffle()
	var space := player.get_world_3d().direct_space_state
	for s in spots:
		var d := Vector2(s.x - player.global_position.x, s.z - player.global_position.z).length()
		if d < min_d or d > max_d:
			continue
		var head: Vector3 = s + Vector3(0, 1.75, 0)
		if player.camera.is_position_in_frustum(head):
			continue                                # never pops into view; it is simply there when you turn
		var q := PhysicsRayQueryParameters3D.create(_eye(), head)
		q.collision_mask = 1
		if not space.intersect_ray(q).is_empty():
			continue                                # needs a clear line so that turning reveals it
		stranger.place(s)
		_fear(0.2)
		return true
	return false


## When the stranger is stared at and vanishes: the lights stutter and the room goes quiet.
func on_stranger_vanished(by_gaze: bool) -> void:
	if by_gaze:
		var cell := _pcell()
		if cell != "":
			Sfx.play_at("lamp_buzz", player.global_position + Vector3(0, 2.0, 0), -6.0, 8.0, 2.0)
			for i in 3:
				apartment.set_room_lit(cell, false)
				await _wait(0.07)
				apartment.set_room_lit(cell, true)
				await _wait(0.1)
		if story and story.ambience:
			story.ambience.hush(5.0, 0.8)
		_fear(0.12)
