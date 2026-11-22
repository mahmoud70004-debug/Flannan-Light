class_name Story
extends Node
## The game's flow: the ten days, Martin's tasks, what he says, the phone and answering machine, the
## night between days, and the ending. Days.DATA holds the content; this node runs it.
##
## Interactions come in as `used(id)` from the flat. An id either advances the day's current task
## (tasks are lists of steps, done in order), is a special action (the bed, the phone), or is simply
## examined (Martin says something about it).

signal finished                              ## the game is over: back to the title

const STEP_SAY := {
	"fridge": "Bread. Cheese gone soft. A jar of something.",
	"trash": "The bin is full. The smell is thick enough to chew.",
	"wardrobe": "Just my clothes, on their hangers.",
	"dad_boxes": "Dad's boxes. I lift a lid.",
	"jack_desk": "Jack's old desk.",
}
const DOC_ON_STEP := ["dad_boxes", "jack_desk"]      ## steps that also show a document, the first time

var apartment: Apartment
var player: Player
var hud: Hud
var director: Director
var stranger: Stranger
var ambience: Ambience
var controls: TouchControls

var busy := false
var locked := false                  ## movement and use are off (the ending); the camera can still turn
var fear := 0.0
var fear_override := -1.0
var ringing := false

var _spike := 0.0
var _clock := 0.0
var _ring_player: AudioStreamPlayer3D
var _ring_time := 0.0
var _final_stage := false
var _near_final := 0.0
var _hint_timer := 0.0
var last_knock := -999.0
var _ended := false


func is_free() -> bool:
	return not busy and not hud.doc_open and not hud.card_open and not hud.menu_open


func boost_fear(amount: float) -> void:
	_spike = clampf(_spike + amount, 0.0, 0.45)


func _process(delta: float) -> void:
	_clock += delta
	if is_free():
		GameState.play_seconds += delta
	_spike = maxf(_spike - delta * 0.12, 0.0)
	var d := Days.get_day(GameState.day)
	var next := Days.get_day(mini(GameState.day + 1, Days.COUNT))
	var prog := clampf(GameState.play_seconds / 420.0, 0.0, 1.0) * 0.7
	fear = clampf(lerpf(d["fear"], next["fear"], prog) + 0.04 * sin(_clock * 0.6) + _spike, 0.0, 1.0)
	if fear_override >= 0.0:
		fear = fear_override
	if is_free():
		_hint_timer += delta
		if _hint_timer > 85.0:
			_hint_timer = 0.0
			_give_hint()
	if ringing:
		_ring_time += delta
		if _ring_time > 34.0:
			stop_ring()
	if _final_stage and not _ended and stranger.state != Stranger.State.HIDDEN and is_free():
		if stranger.distance_to_player() < 2.5:
			_near_final += delta
			if _near_final > 1.5:
				_ending()
		else:
			_near_final = 0.0


## After a long time with no progress Martin thinks aloud about what is left to do.
func _give_hint() -> void:
	var data := Days.get_day(GameState.day)
	if data.get("final", false) and _final_stage:
		hud.say("It's waiting for me in the living room.")
		return
	for t in data["tasks"]:
		if GameState.is_done(t["id"]):
			continue
		var idx: int = GameState.step_index.get(t["id"], 0)
		var id: String = t["steps"][mini(idx, t["steps"].size() - 1)]
		hud.say(Days.HINT.get(id, "I should do something about " + str(t["text"]).to_lower() + "."))
		return
	if not data.get("final", false):
		hud.say("I should get some sleep.")


# --- starting a day ---------------------------------------------------------------------------------------

func _task_list(data: Dictionary) -> Array:
	var out: Array = []
	for t in data["tasks"]:
		out.append({"text": t["text"], "done": GameState.is_done(t["id"])})
	out.append({"text": "Go to sleep" if not data.get("final", false) else "...", "done": false})
	return out


func show_tasks(seconds := 6.0) -> void:
	var data := Days.get_day(GameState.day)
	hud.show_tasks("TODAY", _task_list(data), seconds)


## Look-dev and tests: the flat as it is on the current day, with no card, no director and no controls locked.
func show_debug_day() -> void:
	var data := Days.get_day(GameState.day)
	_apply_environment(data)
	director.enabled = false
	controls.show_photo = GameState.day >= 4


## Look-dev: put the game into one of its moments without playing to it (`--show=<name>`).
func debug_show(what: String) -> void:
	match what:
		"tasks":
			show_tasks(0.0)
		"doc":
			var d := Docs.get_doc("letter")
			hud.show_doc(d["title"], d["body"])
		"say":
			hud.say("\"Psychological problems.\"", 60.0)
			hud.caption("JACK:  Martin… it's Jack. Again.", 60.0)
		"stranger":
			stranger.approach_step = 0.0
			stranger.place(Vector3(-5.5, 0, -4.9))
			stranger.set_process(false)
		"stranger_living":
			stranger.place(Vector3(2.4, 0, -3.4))
			stranger.set_process(false)
		"final":
			for c in apartment.lamps:
				apartment.set_room_lit(c, false)
			apartment.set_tv(true)
			stranger.place(Vector3(2.3, 0.0, -4.2))
			stranger.set_process(false)
		"final_face":
			for c in apartment.lamps:
				apartment.set_room_lit(c, false)
			apartment.set_tv(true)
			stranger.place(Vector3(1.6, 0.0, -3.6))
			stranger.set_process(false)
			stranger.reveal_as_martin()
		"epilogue":
			apartment.show_epilogue()
		"coat_gone":
			apartment.set_movable_visible("coat", false)


## Begins (or resumes) the current day: the black card, waking in bed, the list on the note.
func start_day() -> void:
	busy = true
	var data := Days.get_day(GameState.day)
	director.start_day(data)
	stop_ring()
	_final_stage = false
	_ended = false
	stranger.vanish()
	_apply_environment(data)
	GameState.queue_vm(_day_vm(data))        # today's message is on the machine, ring or no ring
	GameState.play_seconds = 0.0
	hud.hide_tasks()
	player.set_physics_process(false)
	player.position = apartment.wake_point()
	player.rotation.y = apartment.wake_yaw()
	player.set_pitch(0.0)
	player.eye_drop = 0.0
	player.velocity = Vector3.ZERO
	await hud.card([data["title"] + "  ·  " + data["sub"]] + data["intro"])
	player.set_physics_process(true)
	await hud.fade(0.0, 1.6)
	controls.show_photo = GameState.day >= 4
	show_tasks(7.0)
	_hint_timer = 0.0
	if GameState.day == 4 and not GameState.flag("hint_photo"):
		GameState.set_flag("hint_photo")
		hud.say("My phone has a camera. The PHOTO button, up there.", 4.5)
	if GameState.day == 1 and not GameState.flag("hint_shown"):
		GameState.set_flag("hint_shown")
		hud.say("Walk with the left thumb. Look with the right. USE to touch things.", 5.5)
	busy = false
	_check_final()


func _apply_environment(data: Dictionary) -> void:
	var i := 0
	for f in apartment.swarms:
		(f as Flies).intensity = clampf(maxf(float(data["flies"]), 0.6) * (1.0 if i == 0 else 0.9), 0.0, 1.0)
		i += 1
	apartment.set_movable_visible("coat", GameState.day < 8)
	for room in ["bed2", "bath", "storage"]:
		apartment.set_room_lit(room, false)
	for room in ["entry", "kitchen", "living", "hall", "bed1", "living_floor"]:
		apartment.set_room_lit(room, true)
	apartment.set_tv(false)
	ambience.set_day(GameState.day)
	var night := clampf(float(GameState.day - 1) / 8.0, 0.0, 1.0)                 # the windows darken as the days go by
	var b := lerpf(2.3, 0.55, night)
	apartment.set_window_light(Color(b, b, b * 1.06))
	apartment.set_skyline(GameState.day >= 6)


# --- using things -------------------------------------------------------------------------------------------

func on_used(id: String) -> void:
	if not is_free():
		return
	var data := Days.get_day(GameState.day)
	if id == "bed1":
		_try_sleep(data)
		return
	if id == "phone":
		_use_phone(data)
		return
	if _advance_task(id, data):
		_hint_timer = 0.0
		return
	_examine(id)


## Switching on the TV: the news, getting stranger as the days go on.
func _use_tv() -> void:
	busy = true
	apartment.set_tv(true)
	apartment.set_tv_level(0.38)
	var line: String = Days.TV[clampi(GameState.day, 1, Days.COUNT) - 1]
	hud.caption("NEWS:  " + line, 5.0)
	await get_tree().create_timer(5.5).timeout
	apartment.set_tv(false)
	busy = false


func _examine(id: String) -> void:
	_hint_timer = 0.0
	if id == "tv":
		_use_tv()
		return
	if id == "laptop" and GameState.day in [5, 6, 8] and not GameState.flag("notes_%d" % GameState.day):
		GameState.set_flag("notes_%d" % GameState.day)
		busy = true
		var nd := Docs.get_doc("notes_%d" % GameState.day)
		await hud.read_doc(nd["title"], nd["body"])
		busy = false
		boost_fear(0.1)
		return
	if id == "front_door" and _clock - last_knock < 45.0:
		hud.say_all(Days.peephole(GameState.day))
		if GameState.day >= 6:
			boost_fear(0.12)
		return
	var lines := Days.examine(id, GameState.day)
	if not lines.is_empty():
		hud.say_all(lines)


## The task whose next step is `id`, advancing it; returns true if an interaction was consumed.
func _advance_task(id: String, data: Dictionary) -> bool:
	for t in data["tasks"]:
		var tid: String = t["id"]
		if GameState.is_done(tid):
			continue
		var idx: int = GameState.step_index.get(tid, 0)
		var steps: Array = t["steps"]
		if idx >= steps.size() or steps[idx] != id:
			continue
		GameState.step_index[tid] = idx + 1
		_do_step(t, id, idx + 1 >= steps.size())
		return true
	return false


func _do_step(t: Dictionary, id: String, last: bool) -> void:
	busy = true
	if id == "sofa":
		await _pass_time("eat")
	elif id == "shower":
		await _pass_time("shower")
	if (id in DOC_ON_STEP) and not GameState.flag("doc_" + id):
		GameState.set_flag("doc_" + id)
		var doc := Docs.get_doc(id)
		await hud.read_doc(doc["title"], doc["body"])
	if last:
		if t.has("doc"):
			var doc := Docs.get_doc(t["doc"])
			var doc_title: String = doc["title"]
			if t["doc"] == "photos":
				doc_title = "Photos (%d)" % maxi(GameState.photos, 1)
			await hud.read_doc(doc_title, doc["body"])
		GameState.finish_task(t["id"])
		hud.say_all(t.get("say", []))
		boost_fear(0.04)
		show_tasks(5.0)
	else:
		if STEP_SAY.has(id) and not (id in DOC_ON_STEP):
			hud.say(STEP_SAY[id])
	busy = false
	GameState.save()
	_check_final()


## Time passes (eating, washing): a short fade out and in.
func _pass_time(kind: String) -> void:
	await hud.fade(1.0, 1.1)
	if kind == "shower":
		Sfx.play("drip", -4.0)
	await get_tree().create_timer(2.0).timeout
	await hud.fade(0.0, 1.1)


# --- taking a photo with the phone ------------------------------------------------------------------------------

func take_photo() -> void:
	if not is_free() or GameState.day < 4:
		return
	GameState.photos += 1
	Sfx.play("shutter", -2.0)
	hud.flash()
	var data := Days.get_day(GameState.day)
	if stranger.state != Stranger.State.HIDDEN and stranger.is_seen():
		hud.say("It's not in the picture.")
		boost_fear(0.15)
	if not _advance_task(Days.PHOTO_STEP, data):
		if GameState.photos == 1:
			hud.say("Evidence. I need evidence.")


# --- the phone and the answering machine -----------------------------------------------------------------------------

## The message that belongs to today ("" if none): the day's own, else the one a phone task is waiting for.
func _day_vm(data: Dictionary) -> String:
	if data.has("vm"):
		return str(data["vm"])
	var vm := ""
	for t in data["tasks"]:
		if t.has("vm") and not GameState.is_done(t["id"]):
			vm = t["vm"]
	return vm


func start_ring() -> void:
	if ringing:
		return
	var data := Days.get_day(GameState.day)
	var vm := _day_vm(data)
	GameState.queue_vm(vm)
	ringing = true
	_ring_time = 0.0
	var pos: Vector3 = apartment.pois.get("phone", Vector3(-6.0, 0.0, -4.9)) + Vector3(0, 0.8, 0)
	_ring_player = Sfx.loop_at("phone_ring", pos, 4.0, 30.0, 4.0)
	boost_fear(0.1)


func stop_ring() -> void:
	ringing = false
	if _ring_player and is_instance_valid(_ring_player):
		_ring_player.stop()
		_ring_player.queue_free()
	_ring_player = null


## The message a still-unfinished phone task is waiting for ("" if no task needs the phone right now).
func _needed_vm(data: Dictionary) -> String:
	for t in data["tasks"]:
		if GameState.is_done(t["id"]):
			continue
		var idx: int = GameState.step_index.get(t["id"], 0)
		if t["steps"].size() > idx and t["steps"][idx] == "phone":
			return str(t.get("vm", ""))
	return ""


func _phone_task_waiting(data: Dictionary) -> bool:
	for t in data["tasks"]:
		if GameState.is_done(t["id"]):
			continue
		var idx: int = GameState.step_index.get(t["id"], 0)
		if t["steps"].size() > idx and t["steps"][idx] == "phone":
			return true
	return false


func _use_phone(data: Dictionary) -> void:
	stop_ring()
	if not GameState.pending.is_empty():
		_play_pending()
		return
	if data.get("final", false) and _phone_task_waiting(data):
		_call_jack(data)
		return
	hud.say("The machine light isn't blinking.")


## Plays every message waiting on the machine, oldest first. Only the message a phone task is waiting
## for counts toward that task; an older one just plays (and the right one still comes when it arrives).
func _play_pending() -> void:
	while not GameState.pending.is_empty():
		var name: String = GameState.pending[0]
		var data := Days.get_day(GameState.day)
		var counts := name == _needed_vm(data)
		await _play_vm(name, counts)


func _vm_data(name: String) -> Dictionary:
	var path := "res://assets/audio/%s.json" % name
	if FileAccess.file_exists(path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			return parsed
	return {"duration": 3.0, "lines": []}


## Plays a message from the phone with captions. A voicemail comes off the machine (tones, then Jack alone);
## a call is picked up live: Martin answers, flat and late, and Jack's lines carry on around him.
## `count_task`: a phone task waiting on it is advanced.
func _play_vm(name: String, count_task: bool) -> void:
	busy = true
	var info := _vm_data(name)
	var is_call: bool = info.get("call", false)
	Sfx.play("handset", -3.0)
	await get_tree().create_timer(0.6).timeout
	if not is_call:
		Sfx.play("machine_new", -2.0)
		await get_tree().create_timer(Audio.length("machine_new") + 0.3).timeout
		Sfx.play("machine_beep", -6.0)
		await get_tree().create_timer(0.7).timeout
	Sfx.play(name, 0.0)
	var t0 := 0.0
	for line in info["lines"]:
		var wait_s: float = float(line["t"]) - t0
		if wait_s > 0.0:
			await get_tree().create_timer(wait_s).timeout
		t0 = float(line["t"])
		var who: String = str(line.get("who", "JACK"))
		hud.caption(who + ":  " + str(line["text"]), float(line["d"]) + 0.3)
		if who == "MARTIN":
			boost_fear(0.04)                     # his own voice, wrong in his ear
	var rest: float = float(info["duration"]) - t0
	await get_tree().create_timer(maxf(rest, 0.2) + 0.4).timeout
	if is_call:
		Sfx.play("handset", -3.0)
		await get_tree().create_timer(0.8).timeout
	else:
		Sfx.play("machine_end", -3.0)
		await get_tree().create_timer(Audio.length("machine_end") + 0.4).timeout
	GameState.pending.erase(name)
	if not (name in GameState.heard):
		GameState.heard.append(name)
	GameState.set_flag("heard_" + name)
	boost_fear(0.25)
	busy = false
	if count_task:
		var data := Days.get_day(GameState.day)
		_advance_task("phone", data)
	GameState.save()


## Day 10: Martin phones his brother and gets the voicemail greeting. He says nothing.
func _call_jack(_data: Dictionary) -> void:
	busy = true
	Sfx.play("handset", -3.0)
	await get_tree().create_timer(1.0).timeout
	for i in 4:
		Sfx.play("click", -8.0)
		await get_tree().create_timer(0.25).timeout
	await get_tree().create_timer(1.2).timeout
	var info := _vm_data("jack_greeting")
	Sfx.play("jack_greeting", 0.0)
	for line in info["lines"]:
		await get_tree().create_timer(float(line["t"])).timeout
		hud.caption("JACK:  " + str(line["text"]), float(line["d"]) + 0.3)
	await get_tree().create_timer(float(info["duration"]) - float(info["lines"][0]["t"]) + 0.2).timeout
	Sfx.play("machine_beep", -6.0)
	await get_tree().create_timer(1.0).timeout
	Sfx.play("breath", -4.0)
	await get_tree().create_timer(3.2).timeout
	Sfx.play("handset", -3.0)
	busy = false
	var data := Days.get_day(GameState.day)
	_advance_task("phone", data)


# --- sleeping and the night ----------------------------------------------------------------------------------------------

func _try_sleep(data: Dictionary) -> void:
	if data.get("final", false):
		hud.say("There's no sleeping tonight.")
		return
	for t in data["tasks"]:
		if not GameState.is_done(t["id"]):
			hud.say(Days.NOT_YET[randi() % Days.NOT_YET.size()])
			show_tasks(5.0)
			return
	if not director.all_scripted_fired() and director.enabled:
		hud.say("I'm not tired yet. Something is about to happen.")
		return
	_night(data)


func _night(data: Dictionary) -> void:
	busy = true
	stop_ring()
	hud.hide_tasks()
	hud.say(data["sleep_line"])
	await hud.wait_lines()
	await hud.fade(1.0, 1.6)
	player.set_physics_process(false)
	ambience.hush(6.0, 0.9)
	await get_tree().create_timer(1.5).timeout
	for ev in data["night"]:
		await _night_event(ev)
		await get_tree().create_timer(1.2).timeout
	GameState.next_day()
	director.enabled = true
	await start_day()


func _night_event(name: String) -> void:
	match name:
		"footsteps_door":
			var pts := [Vector3(-1.4, 0.1, -4.9), Vector3(-2.2, 0.1, -4.9), Vector3(-3.0, 0.1, -4.9), Vector3(-3.8, 0.1, -4.9), Vector3(-4.5, 0.1, -5.2), Vector3(-4.9, 0.1, -5.5)]
			for p in pts:
				Sfx.play_at("step_%d" % randi_range(0, 3), p, 0.0, 12.0, 2.5)
				await get_tree().create_timer(0.72).timeout
			await get_tree().create_timer(3.0).timeout
			Sfx.play_at("breath", Vector3(-4.9, 1.0, -5.6), -2.0, 6.0, 1.0)
			await get_tree().create_timer(3.0).timeout
		"knock_front":
			Sfx.play_at("knock3", Vector3(0.1, 1.3, -0.15), 0.0, 20.0, 4.0)
			await get_tree().create_timer(2.5).timeout
			Sfx.play_at("knock1", Vector3(0.1, 1.3, -0.15), 0.0, 20.0, 4.0)
			await get_tree().create_timer(3.0).timeout
		"whisper_bed":
			Sfx.play_at("whisper_%d" % randi_range(0, 4), Vector3(-4.9, 1.0, -8.3), 0.0, 6.0, 1.0)
			await get_tree().create_timer(3.5).timeout
		"stranger_bed":
			await _wake_scene(Vector3(-4.85, 0.05, -8.45), PI, Vector3(-4.85, 0.0, -6.4), 0.62)
		"stranger_hall":
			await _wake_scene(Vector3(-1.5, 0.05, -4.9), PI / 2.0, Vector3(-5.5, 0.0, -4.9), 0.0)


## Martin wakes (or finds himself) somewhere in the dark and the stranger is standing there.
func _wake_scene(player_pos: Vector3, yaw: float, stranger_pos: Vector3, eye_drop: float) -> void:
	player.position = player_pos
	player.rotation.y = yaw
	player.set_pitch(0.0)
	player.eye_drop = eye_drop
	var lit: Array = []
	for c in apartment.lamps:
		if apartment.room_lit(c):
			lit.append(c)
		apartment.set_room_lit(c, false)
	stranger.place(stranger_pos)
	stranger.set_process(false)
	Sfx.play("heartbeat", -6.0)
	await hud.fade(0.0, 2.2)
	await get_tree().create_timer(3.2).timeout
	boost_fear(0.3)
	Sfx.play_at("lamp_buzz", player_pos + Vector3(0, 2, 0), -4.0, 8.0, 2.0)
	for i in 4:
		apartment.set_room_lit(apartment.cell_at(player_pos), i % 2 == 0)
		await get_tree().create_timer(0.09).timeout
	apartment.set_room_lit(apartment.cell_at(player_pos), false)
	stranger.vanish()
	stranger.set_process(true)
	await get_tree().create_timer(1.6).timeout
	await hud.fade(1.0, 1.4)
	player.eye_drop = 0.0
	for c in lit:
		apartment.set_room_lit(c, true)


# --- the last day and the ending ---------------------------------------------------------------------------------------------

func _check_final() -> void:
	var data := Days.get_day(GameState.day)
	if not data.get("final", false) or _final_stage:
		return
	for t in data["tasks"]:
		if not GameState.is_done(t["id"]):
			return
	_begin_final()


func _begin_final() -> void:
	_final_stage = true
	director.enabled = false
	busy = true
	stop_ring()
	ambience.hush(10.0, 0.95)
	hud.say("The air changes.")
	await hud.wait_lines()
	for c in apartment.lamps:
		apartment.set_room_lit(c, false)
	apartment.set_tv(true)
	Sfx.play_at("tv_static", apartment.tv_position(), -3.0, 14.0, 2.0)
	await get_tree().create_timer(2.0).timeout
	var spot := Vector3(2.3, 0.0, -4.2)
	stranger.approach_step = 0.0
	stranger.place(spot)
	stranger.final_mode = true
	stranger.set_interactive(true)
	stranger.body().interacted.connect(_ending, CONNECT_ONE_SHOT)
	hud.say("There you are.")
	boost_fear(0.4)
	busy = false


func _ending() -> void:
	if _ended:
		return
	_ended = true
	busy = true
	locked = true
	fear_override = 1.0
	var d := stranger.global_position - player.camera.global_position
	player.rotation.y = atan2(-d.x, -d.z)
	player.set_pitch(atan2(d.y - 0.1, Vector2(d.x, d.z).length()))
	hud.say("It's wearing my coat.")
	await get_tree().create_timer(3.5).timeout
	stranger.reveal_as_martin()
	Sfx.play("heartbeat", -2.0)
	hud.say("It has my face.")
	await get_tree().create_timer(4.0).timeout
	hud.say("There was never anyone else.")
	await get_tree().create_timer(3.5).timeout
	hud.fade_color(Color.WHITE)
	await hud.fade(1.0, 4.0)
	Sfx.clear()
	ambience.stop_all()
	await hud.card(["It was me.", "It was only ever me."], 2.8)
	hud.fade_color(Color.BLACK)
	await _epilogue()


func _epilogue() -> void:
	GameState.ended = true
	GameState.save()
	stranger.vanish()
	stranger.set_interactive(false)
	director.enabled = false
	player.set_physics_process(false)
	fear_override = 0.28
	apartment.show_epilogue()
	player.position = Vector3(0.1, 0.05, -0.75)
	player.rotation.y = 0.0
	player.set_pitch(0.0)
	player.velocity = Vector3.ZERO
	ambience.setup(apartment)
	ambience.hush(0.0, 0.0)
	hud.set_fade(1.0)
	await hud.card(["41 days later."], 2.4)
	hud.set_fade(1.0)
	player.set_physics_process(true)
	await hud.fade(0.0, 2.5)
	# He walks in slowly; nobody is steering.
	var sofa_pos := Vector3(1.0, 0.7, -6.5)
	player.move_input = Vector2(0, -0.45)
	await get_tree().create_timer(3.2).timeout
	player.move_input = Vector2.ZERO
	var d := sofa_pos - player.camera.global_position
	player.rotation.y = atan2(-d.x, -d.z)
	player.set_pitch(atan2(d.y, Vector2(d.x, d.z).length()) * 0.6)
	await get_tree().create_timer(2.5).timeout
	var messages := [["vm5", "day 16"], ["vm6", "day 30"], ["vm7", "day 41"]]
	for m in messages:
		var pos: Vector3 = apartment.pois.get("phone", Vector3(-6.0, 0.0, -4.9)) + Vector3(0, 0.8, 0)
		var rp := Sfx.loop_at("phone_ring", pos, 5.0, 40.0, 6.0)
		await get_tree().create_timer(7.5).timeout
		if rp and is_instance_valid(rp):
			rp.stop()
			rp.queue_free()
		hud.caption("— " + str(m[1]) + " —", 2.5)
		await get_tree().create_timer(2.0).timeout
		# The machine answers with Martin's own cheerful voice from long ago
		Sfx.play_at("greeting", pos, 0.0, 40.0, 6.0)
		hud.caption("MARTIN:  Hey, you've reached Martin. I can't get to the phone right now. Leave a message, and I'll call you back.", 5.6)
		await get_tree().create_timer(Audio.length("greeting") + 0.3).timeout
		Sfx.play_at("machine_beep", pos, -4.0, 40.0, 6.0)
		await get_tree().create_timer(0.8).timeout
		var info := _vm_data(m[0])
		Sfx.play_at(m[0], pos, 0.0, 40.0, 6.0)
		var t0 := 0.0
		for line in info["lines"]:
			var wait_s: float = float(line["t"]) - t0
			if wait_s > 0.0:
				await get_tree().create_timer(wait_s).timeout
			t0 = float(line["t"])
			hud.caption(str(line.get("who", "JACK")) + ":  " + str(line["text"]), float(line["d"]) + 0.3)
		await get_tree().create_timer(maxf(float(info["duration"]) - t0, 0.2) + 1.5).timeout
	await get_tree().create_timer(5.0).timeout
	await hud.fade(1.0, 3.0)
	ambience.stop_all()
	Sfx.clear()
	await hud.card(["Martin Reed was found forty-one days later.", "A neighbour complained about the smell.", "Nobody had reported him missing."], 3.4)
	await hud.card(["NO ONE HOME"], 4.0)
	finished.emit()
