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
var _phase := "day"                       ## "day" or "night" (the playable 3 a.m. walk)
var _notice_t := {}                       ## anomaly id -> seconds it has been looked at
var _night_found := false
var _night_loops: Array = []              ## looping sounds that belong to the day or night (a tap, a dial tone, static)
var _dread := 0.0                         ## 0..1: time spent in the dark at night; at 1 he loses the time
var _hall_goes_dark := false
var _lost_time := false
var _dread_hint := false
var _in_call := false                     ## on the phone: he can walk about, but not use anything
var _warmed := false
var _announced := ""                      ## the task whose objective is on screen ("_sleep": go to bed; "": a quiet spell)
var _task_timer := -1.0                   ## seconds until the next thought and objective (< 0: none pending)
var last_knock := -999.0
var _ended := false


func is_free() -> bool:
	return not busy and not _in_call and not hud.doc_open and not hud.card_open and not hud.menu_open


func boost_fear(amount: float) -> void:
	_spike = clampf(_spike + amount * 0.75, 0.0, 0.4)


func _process(delta: float) -> void:
	_clock += delta
	if is_free():
		GameState.play_seconds += delta
	_spike = maxf(_spike - delta * 0.12, 0.0)
	var d := Days.get_day(GameState.day)
	var next := Days.get_day(mini(GameState.day + 1, Days.COUNT))
	var prog := _task_progress(d) * 0.8                                          # the fear follows what has been done, not the clock
	fear = clampf(lerpf(d["fear"], next["fear"], prog) + 0.04 * sin(_clock * 0.6) + _spike, 0.0, 1.0)
	fear = clampf(fear + _dread * 0.4, 0.0, 1.0)                                   # the dark makes everything worse
	if fear_override >= 0.0:
		fear = fear_override
	_check_anomalies(delta)
	_light_rule()
	_night_tick(delta)
	if _task_timer >= 0.0 and is_free():
		_task_timer = maxf(_task_timer - delta, 0.0)
		if _task_timer == 0.0 and not director.is_busy() and not hud.is_talking():
			_task_timer = -1.0
			_announce()
	if is_free() and _announced != "":
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


# --- things that are out of place -------------------------------------------------------------------------------

## Looking at something that is out of place for a moment makes Martin notice it: a line, a note in the notebook,
## a low thump. Nothing is pressed; the room just tells him.
func _light_rule() -> void:
	if director.enabled and not _final_stage and stranger.state != Stranger.State.HIDDEN and not stranger.final_mode:
		var sc := apartment.cell_at(stranger.global_position)
		if sc != "" and apartment.room_lit(sc):
			stranger.vanish()                              # it cannot stand in the light, in any phase


func _check_anomalies(delta: float) -> void:
	if _phase != "day" or not is_free() or hud.is_talking():
		return
	var data := Days.get_day(GameState.day)
	var cam := player.camera
	var cell := apartment.cell_at(player.global_position)
	for id in data.get("anomalies", []):
		if GameState.has_evidence("a_" + id):
			continue
		var a: Dictionary = Days.ANOMALY[id]
		var to: Vector3 = (a["at"] as Vector3) - cam.global_position
		var dist := to.length()
		var everywhere: bool = float(a["radius"]) > 50.0
		var looking := everywhere
		if not everywhere:
			if dist > float(a["radius"]) or cam.global_transform.basis.z.dot(-to.normalized()) < 0.5:
				_notice_t[id] = 0.0
				continue
			var acell := apartment.cell_at(Vector3(a["at"].x, 0.05, a["at"].z))
			looking = acell == cell or acell in apartment.visible_cells(cell)
		if not looking:
			continue
		_notice_t[id] = float(_notice_t.get(id, 0.0)) + delta
		if _notice_t[id] >= (2.5 if everywhere else 0.7):
			_notice(id)
			return


func _notice(id: String) -> void:
	var a: Dictionary = Days.ANOMALY[id]
	if not GameState.add_evidence("a_" + id, str(a["evidence"])):
		return
	Sfx.play("thump", -13.0)
	hud.say_all(a["lines"])
	hud.caption("NOTEBOOK  +1", 2.4)
	boost_fear(0.1)
	GameState.save()


# --- starting a day ---------------------------------------------------------------------------------------

## The first task that is not done: the one Martin is on.
func _current_task(data: Dictionary) -> Dictionary:
	for t in data["tasks"]:
		if not GameState.is_done(t["id"]):
			return t
	return {}


func _task_progress(data: Dictionary) -> float:
	var n: int = (data["tasks"] as Array).size()
	var done := 0
	for t in data["tasks"]:
		if GameState.is_done(t["id"]):
			done += 1
	return float(done) / float(maxi(n, 1))


## Martin's list shows what he has done and what he is on; what comes next stays unknown.
func _task_list(data: Dictionary) -> Array:
	var out: Array = []
	for t in data["tasks"]:
		var done := GameState.is_done(t["id"])
		out.append({"text": t["text"], "done": done})
		if not done:
			break
	if _announced == "_sleep":
		out.append({"text": "Go to sleep", "done": false})
	return out


## The quiet between two tasks: longer at first, a little shorter as the days press in.
func _gap() -> float:
	return lerpf(16.0, 10.0, clampf(float(GameState.day - 1) / 9.0, 0.0, 1.0))


## Martin thinks aloud about the next thing, then the objective appears at the top of the screen.
func _announce() -> void:
	var data := Days.get_day(GameState.day)
	var t := _current_task(data)
	if t.is_empty():
		await _announce_sleep(data)
		return
	var tid: String = t["id"]
	var started: bool = GameState.step_index.get(tid, 0) > 0
	if t.has("vm"):
		GameState.queue_vm(str(t["vm"]))                           # the message he is waiting for is on the machine
	_announced = tid
	director.notify("current", tid)
	director.quiet(18.0)
	_hint_timer = 0.0
	if not started:
		var think := Days.think_for(t)
		if think != "":
			hud.say(think)
			await hud.wait_lines()
			await get_tree().create_timer(0.4).timeout
	_refresh_objective()


func _announce_sleep(data: Dictionary) -> void:
	if data.get("final", false):
		return
	if director.enabled and not director.all_scripted_fired():
		_task_timer = 4.0                                          # the day's last moments first
		return
	_announced = "_sleep"
	hud.say("I should try to sleep.")
	await hud.wait_lines()
	_refresh_objective()


func _refresh_objective() -> void:
	if _announced == "_sleep":
		hud.set_objective("Go to bed")
		return
	var t := _current_task(Days.get_day(GameState.day))
	if _announced == "" or t.is_empty() or t["id"] != _announced:
		hud.set_objective("")
		return
	hud.set_objective(Days.objective(t, GameState.step_index.get(t["id"], 0)))


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
	_phase = "day"
	_notice_t = {}
	_hall_goes_dark = false
	_clear_loops()
	if not _warmed:
		_warmed = true
		await _prewarm()
	_apply_environment(data)
	GameState.play_seconds = 0.0
	hud.hide_tasks()
	player.set_physics_process(false)
	var spot: Array = apartment.wake_spot(str(data.get("wake", "bed1")))
	player.position = spot[0]
	player.rotation.y = spot[1]
	player.set_pitch(spot[2])
	player.eye_drop = 0.0
	player.velocity = Vector3.ZERO
	var intro: Array = (data["intro"] as Array).duplicate()
	if _lost_time and GameState.day > 1:
		intro.insert(0, "I don't remember the rest of the night.")
	_lost_time = false
	await hud.card([data["title"] + "  ·  " + data["sub"]] + intro)
	var wake_note: String = Days.WAKE_EVIDENCE.get(data.get("wake", "bed1"), "")
	if wake_note != "" and GameState.add_evidence("wake_%d" % GameState.day, wake_note):
		hud.caption("NOTEBOOK  +1", 2.4)
	player.set_physics_process(true)
	await hud.fade(0.0, 1.6)
	controls.show_photo = GameState.day >= 4
	_hint_timer = 0.0
	_announced = ""
	hud.set_objective("")
	var progress := _task_progress(data) > 0.0 or not GameState.step_index.is_empty()
	_task_timer = 4.0 if progress else (9.0 if GameState.day == 1 else 6.0)   # first, time to look around
	if GameState.day == 4 and not GameState.flag("hint_photo"):
		GameState.set_flag("hint_photo")
		hud.say("My phone has a camera. The PHOTO button, up there.", 4.5)
	if GameState.day == 1 and not GameState.flag("hint_shown"):
		GameState.set_flag("hint_shown")
		hud.say("Walk with the left thumb. Look with the right. USE to touch things.", 5.5)
	busy = false
	_check_final()


## Everything the game will ever draw or play is shown or loaded once, behind a black screen, so that no shader
## compiles and no sound loads in the middle of a scare (the first minutes of a phone session stalled otherwise).
func _prewarm() -> void:
	hud.set_fade(1.0)
	Audio.warm()
	var old_viewer := apartment.viewer
	apartment.show_everything()
	for c in apartment.lamps:
		apartment.set_room_lit(c, true)
	for id in apartment.movables:
		apartment.set_movable_visible(id, true)
	apartment.set_tv(true)
	var fwd := -player.global_transform.basis.z
	stranger.place(player.global_position + fwd * 2.6)
	stranger.set_process(false)
	for i in 4:
		await get_tree().process_frame
	stranger.vanish()
	stranger.set_process(true)
	apartment.viewer = old_viewer


func _apply_environment(data: Dictionary) -> void:
	var i := 0
	for f in apartment.swarms:
		(f as Flies).intensity = clampf(maxf(float(data["flies"]), 0.6) * (1.0 if i == 0 else 0.9), 0.0, 1.0)
		i += 1
	apartment.set_day_state(data.get("anomalies", []), data.get("lit", ["living", "hall"]), data.get("all_open", false))
	var tv_on: bool = data.get("tv_on", false)
	apartment.set_tv(tv_on)
	if tv_on:
		apartment.set_tv_level(0.38)
		_loop("tv", Sfx.loop_at("tv_static", apartment.tv_position(), -12.0, 9.0, 1.5))
	if "tub_water" in data.get("anomalies", []):
		_loop("tap", Sfx.loop_at("tap_run", apartment.pois.get("shower", Vector3(-5.4, 0, -2.4)) + Vector3(0, 0.6, 0), -8.0, 8.0, 1.5))
	ambience.set_day(GameState.day)
	var night := clampf(float(GameState.day - 1) / 8.0, 0.0, 1.0)                 # it is always a wet night out there, darker as the days go by
	var b := lerpf(1.15, 0.62, night)
	apartment.set_window_light(Color(b, b, b * 1.05))
	apartment.set_skyline(GameState.day >= 6)


func _loop(key: String, player_node: Node) -> void:
	if player_node:
		player_node.set_meta("key", key)
		_night_loops.append(player_node)


func _stop_loop(key: String) -> void:
	for p in _night_loops.duplicate():
		if is_instance_valid(p) and p.get_meta("key", "") == key:
			Sfx.stop(p)
			_night_loops.erase(p)


func _clear_loops() -> void:
	for p in _night_loops:
		if is_instance_valid(p):
			Sfx.stop(p)
	_night_loops.clear()


# --- using things -------------------------------------------------------------------------------------------

func on_used(id: String) -> void:
	if not is_free():
		return
	var data := Days.get_day(GameState.day)
	if _phase == "night":
		_night_used(id, data)
		return
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
	if apartment.tv_is_on():
		_stop_loop("tv")
		apartment.set_tv(false)
		Sfx.play("click", -4.0)
		hud.say("Off.")
		return
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
	var t := _current_task(data)
	if t.is_empty() or t["id"] != _announced:
		return false
	var tid: String = t["id"]
	var idx: int = GameState.step_index.get(tid, 0)
	var steps: Array = t["steps"]
	if idx >= steps.size() or steps[idx] != id:
		return false
	GameState.step_index[tid] = idx + 1
	_do_step(t, id, idx + 1 >= steps.size())
	return true


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
		_announced = ""
		hud.set_objective("")
		director.notify("done", t["id"])
		if _current_task(Days.get_day(GameState.day)).is_empty():
			director.rush()                                  # what is left of the day happens now, so the bed is not stuck
		_task_timer = _gap()                                 # a quiet stretch to look around before the next thing
	else:
		if STEP_SAY.has(id) and not (id in DOC_ON_STEP):
			hud.say(STEP_SAY[id])
		_refresh_objective()
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
		Sfx.fade_stop(_ring_player, 0.3)
	_ring_player = null


## The message a still-unfinished phone task is waiting for ("" if no task needs the phone right now).
## The message the task Martin is on is waiting for ("" if it is not a phone task right now).
func _needed_vm(data: Dictionary) -> String:
	var t := _current_task(data)
	if t.is_empty() or t["id"] != _announced:
		return ""
	var idx: int = GameState.step_index.get(t["id"], 0)
	if t["steps"].size() > idx and t["steps"][idx] == "phone":
		return str(t.get("vm", ""))
	return ""


func _phone_task_waiting(data: Dictionary) -> bool:
	var t := _current_task(data)
	if t.is_empty() or t["id"] != _announced:
		return false
	var idx: int = GameState.step_index.get(t["id"], 0)
	return t["steps"].size() > idx and t["steps"][idx] == "phone"


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
	_in_call = true                                       # he can still walk about; the voice comes from the phone, so it fades as he leaves
	var info := _vm_data(name)
	var is_call: bool = info.get("call", false)
	var pos: Vector3 = apartment.pois.get("phone", Vector3(-6.0, 0.0, -4.9)) + Vector3(0, 0.8, 0)
	Sfx.play_at("handset", pos, -12.0, 8.0, 2.0)
	await get_tree().create_timer(0.7).timeout
	if not is_call:
		Sfx.play_at("machine_new", pos, -4.0, 12.0, 2.0)
		await get_tree().create_timer(Audio.length("machine_new") + 0.3).timeout
		Sfx.play_at("machine_beep", pos, -9.0, 12.0, 2.0)
		await get_tree().create_timer(0.7).timeout
	Sfx.play_at(name, pos, 2.0, 12.0, 2.0)
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
		Sfx.play_at("handset", pos, -12.0, 8.0, 2.0)
		await get_tree().create_timer(0.6).timeout
	else:
		Sfx.play_at("machine_end", pos, -5.0, 12.0, 2.0)
		await get_tree().create_timer(Audio.length("machine_end") + 0.4).timeout
	GameState.pending.erase(name)
	if not (name in GameState.heard):
		GameState.heard.append(name)
	GameState.set_flag("heard_" + name)
	boost_fear(0.25)
	_in_call = false
	if count_task:
		var data := Days.get_day(GameState.day)
		_advance_task("phone", data)
	GameState.save()


## Day 10: Martin phones his brother and gets the voicemail greeting. He says nothing.
func _call_jack(_data: Dictionary) -> void:
	_in_call = true
	var pos: Vector3 = apartment.pois.get("phone", Vector3(-6.0, 0.0, -4.9)) + Vector3(0, 0.8, 0)
	Sfx.play_at("handset", pos, -12.0, 8.0, 2.0)
	await get_tree().create_timer(1.0).timeout
	for i in 4:
		Sfx.play_at("click", pos, -10.0, 8.0, 2.0)
		await get_tree().create_timer(0.25).timeout
	await get_tree().create_timer(1.2).timeout
	var info := _vm_data("jack_greeting")
	Sfx.play_at("jack_greeting", pos, 2.0, 12.0, 2.0)
	for line in info["lines"]:
		await get_tree().create_timer(float(line["t"])).timeout
		hud.caption("JACK:  " + str(line["text"]), float(line["d"]) + 0.3)
	await get_tree().create_timer(float(info["duration"]) - float(info["lines"][0]["t"]) + 0.2).timeout
	Sfx.play_at("machine_beep", pos, -9.0, 12.0, 2.0)
	await get_tree().create_timer(1.0).timeout
	Sfx.play_at("breath", pos, -4.0, 8.0, 1.5)
	await get_tree().create_timer(3.2).timeout
	Sfx.play_at("handset", pos, -12.0, 8.0, 2.0)
	_in_call = false
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
			return
	if not director.all_scripted_fired() and director.enabled:
		hud.say("I'm not tired yet. Something is about to happen.")
		return
	_night(data)


func _night(data: Dictionary) -> void:
	busy = true
	stop_ring()
	hud.hide_tasks()
	_announced = ""
	hud.set_objective("")
	hud.say(data["sleep_line"])
	await hud.wait_lines()
	await hud.fade(1.0, 1.6)
	player.set_physics_process(false)
	_clear_loops()
	ambience.hush(6.0, 0.9)
	await get_tree().create_timer(1.5).timeout
	var n: Dictionary = data.get("night", {})
	if n.is_empty():
		_end_night()
		return
	# 3:07 a.m. He is awake in the dark. Only the hall light is on (Dr. Hale's third rule).
	_phase = "night"
	_night_found = false
	_dread = 0.0
	_dread_hint = false
	_hall_goes_dark = bool(n.get("dark", false))
	for c in apartment.lamps:
		apartment.set_room_lit(c, c == "hall")
	apartment.set_tv(false)
	stranger.vanish()
	var spot: Array = apartment.wake_spot("bed1")
	player.position = spot[0]
	player.rotation.y = spot[1]
	player.set_pitch(0.0)
	player.velocity = Vector3.ZERO
	await hud.card(["3:07 a.m."], 2.2)
	hud.set_fade(1.0)
	player.set_physics_process(true)
	await hud.fade(0.0, 1.6)
	busy = false
	await get_tree().create_timer(4.0).timeout           # lie there and listen
	_night_cue(n)
	await get_tree().create_timer(3.0).timeout
	hud.say(str(n["think"]))
	await hud.wait_lines()
	hud.set_objective(str(n["obj"]))


## Where a night sound comes from.
func _cue_pos(key: String) -> Vector3:
	match key:
		"bath": return apartment.pois.get("shower", Vector3(-5.4, 0, -2.4)) + Vector3(0, 0.8, 0)
		"front": return Vector3(0.1, 1.3, -0.15)
		"dining": return apartment.pois.get("dining_food", Vector3(3.9, 0, -5.5)) + Vector3(0, 0.6, 0)
		"phone": return apartment.pois.get("phone", Vector3(-6.0, 0, -4.9)) + Vector3(0, 0.8, 0)
		"bed1door": return Vector3(-4.9, 1.0, -5.75)
		"living": return apartment.pois.get("clock", Vector3(-0.85, 0, -7.0)) + Vector3(0, 1.9, 0)
		"bed2": return apartment.pois.get("jack_desk", Vector3(-3.0, 0, -8.0)) + Vector3(0, 0.8, 0)
		"tv": return apartment.tv_position()
	return Vector3(0.1, 1.3, -0.15)


func _night_cue(n: Dictionary) -> void:
	var pos := _cue_pos(str(n["at"]))
	match str(n["cue"]):
		"tap":
			_loop("tap", Sfx.loop_at("tap_run", pos, -4.0, 14.0, 2.0))
		"knock":
			Sfx.play_at("knock3_front", pos, 0.0, 20.0, 4.0)
			await get_tree().create_timer(2.4).timeout
			Sfx.play_at("knock3_front", pos, -4.0, 20.0, 4.0)
		"chair":
			Sfx.play_at("chair_scrape", pos, 0.0, 16.0, 3.0)
		"phone":
			_loop("phone", Sfx.loop_at("dial_tone", pos, -4.0, 14.0, 2.0))
		"breath":
			Sfx.play_at("breath", pos, 0.0, 8.0, 1.5)
			await get_tree().create_timer(3.0).timeout
			Sfx.play_at("step_1", pos + Vector3(0.4, -0.9, 0), -2.0, 8.0, 1.5)
		"clock":
			Sfx.play_at("thump", pos, -2.0, 14.0, 2.5)
		"steps":
			for i in 5:
				Sfx.play_at("step_%d" % randi_range(0, 3), pos + Vector3(float(i) * 0.15, -0.8, 0), -1.0, 10.0, 2.0)
				await get_tree().create_timer(0.8).timeout
		"tv":
			_loop("tv", Sfx.loop_at("tv_static", pos, -6.0, 14.0, 2.0))
			await get_tree().create_timer(2.0).timeout
			Sfx.play_at("whisper_0", pos, -3.0, 10.0, 1.5)
		"chain":
			Sfx.play_at("chain_rattle", pos, 0.0, 16.0, 3.0)


func _night_used(id: String, data: Dictionary) -> void:
	var n: Dictionary = data.get("night", {})
	if id == "bed1":
		if _night_found:
			_end_night()
		else:
			hud.say("I can't sleep until I know what that was.")
		return
	if _night_found or id != str(n.get("target", "")):
		if id == "tv" and apartment.tv_is_on():
			_use_tv()
		return
	_night_found = true
	_stop_loop("tap")
	_stop_loop("phone")
	_stop_loop("tv")
	hud.set_objective("")
	busy = true
	Sfx.play("thump", -12.0)
	hud.say_all(n["found"])
	GameState.add_evidence("night_%d" % GameState.day, str(n["evidence"]))
	hud.caption("NOTEBOOK  +1", 2.4)
	boost_fear(0.12)
	await hud.wait_lines()
	busy = false
	hud.set_objective("Go back to bed")
	if n.has("figure"):
		await get_tree().create_timer(3.5).timeout
		_spawn_figure(n)


## The figure takes its place for the night: a fixed spot behind or beside where the player will be, so that
## turning round (or looking up from what he found) shows it. It never pops into view; it is simply there.
func _spawn_figure(n: Dictionary) -> void:
	if stranger.state != Stranger.State.HIDDEN or not n.has("figure"):
		return
	stranger.place(n["figure"])
	boost_fear(0.2)


## While the player is in the dark at night: the hall light goes out as he enters the hall, time in the dark
## builds dread, and at full dread the time is lost. Light is safe: a lit room clears the figure and the dread.
func _night_tick(delta: float) -> void:
	if _phase != "night" or busy or not is_free():
		return
	var cell := apartment.cell_at(player.global_position)
	if _hall_goes_dark and cell == "hall":
		_hall_goes_dark = false
		Sfx.play_at("lamp_buzz", player.global_position + Vector3(0, 2.0, 0), -3.0, 8.0, 2.0)
		apartment.set_room_lit("hall", false)
		boost_fear(0.18)
	var data := Days.get_day(GameState.day)
	var dark_night: bool = (data.get("night", {}) as Dictionary).get("dark", false)
	var dim: bool = dark_night and cell != "" and not apartment.room_lit(cell) and cell != "bed1"
	if dim:
		_dread = minf(_dread + delta / 28.0, 1.0)
	else:
		_dread = maxf(_dread - delta / 6.0, 0.0)
	if _dread > 0.6 and not _dread_hint:
		_dread_hint = true
		hud.say("I need a light.")
		Sfx.play("heartbeat", -8.0)
	if _dread >= 1.0:
		_lose_time()


## Too long in the dark: the picture goes, and he is somewhere else when it returns.
func _lose_time() -> void:
	if busy:
		return
	busy = true
	_lost_time = true
	_dread = 0.0
	Sfx.play("heartbeat", -3.0)
	hud.set_objective("")
	stranger.vanish()
	await hud.fade(1.0, 0.7)
	await get_tree().create_timer(2.5).timeout
	GameState.add_evidence("lost_%d" % GameState.day, "I lost time again. I was in the dark, and then I wasn't.")
	_end_night()


func _end_night() -> void:
	busy = true
	_phase = "day"
	_dread = 0.0
	_clear_loops()
	stranger.vanish()
	hud.set_objective("")
	await hud.fade(1.0, 1.0)
	GameState.next_day()
	director.enabled = true
	await start_day()


## Martin's notebook: what he has written down, in order, and what he is on now. Opened from the NOTES button.
func open_notes() -> void:
	if not is_free():
		return
	var data := Days.get_day(GameState.day)
	var t := "RIGHT NOW\n"
	var obj := hud.objective_text()
	t += (obj if obj != "" else "Nothing in particular.") + "\n\nWHAT I'VE WRITTEN DOWN\n"
	if GameState.evidence.is_empty():
		t += "Nothing yet. (Dr. Hale said to write down anything unusual.)"
	for e in GameState.evidence:
		t += "\nDay %d.  %s\n" % [e["day"], e["text"]]
	busy = true
	await hud.read_doc("Notes", t)
	busy = false


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
	_announced = ""
	hud.set_objective("Go to the living room")
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
	hud.say("I'm here.")
	await get_tree().create_timer(3.5).timeout
	stranger.reveal_as_martin()
	Sfx.play("heartbeat", -2.0)
	await get_tree().create_timer(7.0).timeout                      # nobody says anything
	hud.fade_color(Color.WHITE)
	await hud.fade(1.0, 4.0)
	Sfx.clear()
	ambience.stop_all()
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
