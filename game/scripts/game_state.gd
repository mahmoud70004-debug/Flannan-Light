extends Node
## The player's progress through the ten days, saved to user://save.cfg (IndexedDB on the web build).
## Everything the story needs to remember lives here, so scenes can come and go.

signal day_changed(day: int)
signal task_done(id: String)
signal flag_set(name: String)

const PATH := "user://save.cfg"
const VERSION := 1

var day := 1
var tasks_done: Array = []            ## task ids finished today
var step_index := {}                  ## task id -> how many of its steps are done
var flags := {}                       ## story flags (coat_gone, heard_vm1, ...)
var photos := 0                       ## photos taken in total
var play_seconds := 0.0               ## time played today (drives scripted events)
var pending: Array = []               ## voicemails waiting on the machine, in the order they arrived
var heard: Array = []                 ## voicemails already played
var ended := false


func new_game() -> void:
	day = 1
	tasks_done = []
	step_index = {}
	flags = {}
	photos = 0
	play_seconds = 0.0
	pending = []
	heard = []
	ended = false
	day_changed.emit(day)


## A message arrives on the machine (once: never twice, never after it has been heard).
func queue_vm(name: String) -> void:
	if name != "" and not (name in heard) and not (name in pending):
		pending.append(name)


func set_flag(name: String, value: Variant = true) -> void:
	flags[name] = value
	flag_set.emit(name)


func flag(name: String, default: Variant = false) -> Variant:
	return flags.get(name, default)


func finish_task(id: String) -> void:
	if not (id in tasks_done):
		tasks_done.append(id)
		task_done.emit(id)


func is_done(id: String) -> bool:
	return id in tasks_done


## Starts the next day: today's progress is cleared, the day counter moves on.
func next_day() -> void:
	day += 1
	tasks_done = []
	step_index = {}
	play_seconds = 0.0
	day_changed.emit(day)
	save()


func has_save() -> bool:
	return FileAccess.file_exists(PATH)


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", VERSION)
	cfg.set_value("state", "day", day)
	cfg.set_value("state", "tasks_done", tasks_done)
	cfg.set_value("state", "step_index", step_index)
	cfg.set_value("state", "flags", flags)
	cfg.set_value("state", "photos", photos)
	cfg.set_value("state", "pending", pending)
	cfg.set_value("state", "heard", heard)
	cfg.set_value("state", "ended", ended)
	cfg.save(PATH)


func load_game() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK or int(cfg.get_value("meta", "version", 0)) != VERSION:
		return false
	day = clampi(int(cfg.get_value("state", "day", 1)), 1, Days.COUNT)
	tasks_done = cfg.get_value("state", "tasks_done", [])
	step_index = cfg.get_value("state", "step_index", {})
	flags = cfg.get_value("state", "flags", {})
	photos = int(cfg.get_value("state", "photos", 0))
	pending = cfg.get_value("state", "pending", [])
	heard = cfg.get_value("state", "heard", [])
	ended = bool(cfg.get_value("state", "ended", false))
	play_seconds = 0.0
	day_changed.emit(day)
	return true


func erase() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
