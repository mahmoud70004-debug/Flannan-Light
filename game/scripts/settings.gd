extends Node
## User settings, saved to user://settings.cfg (IndexedDB on the web build).

signal changed

const PATH := "user://settings.cfg"
const RENDER_HEIGHTS := [360, 480, 540, 720, 1080]
const VERSION := 4                 ## stored with the file; older looks are discarded

var look_sensitivity: float = 0.0045   ## radians per UI pixel dragged
var render_height: int = 540           ## height of the 3D image; the screen is upscaled from it
var brightness: float = 1.0
var grade: int = 0                     ## index into Film.GRADES
var msaa: int = 0                      ## 0 off, 1 = 2x, 2 = 4x
var shadows: int = 0                   ## 0 off, 1 corridor lamps, 2 every lamp
var show_debug: bool = true


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	look_sensitivity = clampf(cfg.get_value("input", "look_sensitivity", look_sensitivity), 0.001, 0.012)
	show_debug = cfg.get_value("debug", "show_debug", show_debug)
	if int(cfg.get_value("meta", "version", 1)) < VERSION:
		return
	render_height = cfg.get_value("video", "render_height", render_height)
	if not RENDER_HEIGHTS.has(render_height):
		render_height = 540
	brightness = clampf(cfg.get_value("video", "brightness", brightness), 0.6, 1.8)
	grade = clampi(int(cfg.get_value("video", "grade", grade)), 0, Film.GRADES.size() - 1)
	msaa = clampi(int(cfg.get_value("video", "msaa", msaa)), 0, 2)
	shadows = clampi(int(cfg.get_value("video", "shadows", shadows)), 0, 2)


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", VERSION)
	cfg.set_value("input", "look_sensitivity", look_sensitivity)
	cfg.set_value("video", "render_height", render_height)
	cfg.set_value("video", "brightness", brightness)
	cfg.set_value("video", "grade", grade)
	cfg.set_value("video", "msaa", msaa)
	cfg.set_value("video", "shadows", shadows)
	cfg.set_value("debug", "show_debug", show_debug)
	cfg.save(PATH)
	changed.emit()


func cycle_render_height() -> void:
	var i := RENDER_HEIGHTS.find(render_height)
	render_height = RENDER_HEIGHTS[(i + 1) % RENDER_HEIGHTS.size()]
	save()


func cycle_shadows() -> void:
	shadows = (shadows + 1) % 3
	save()


func cycle_grade() -> void:
	grade = (grade + 1) % Film.GRADES.size()
	save()


func cycle_msaa() -> void:
	msaa = (msaa + 1) % 3
	save()
