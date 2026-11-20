extends Node
## User settings, saved to user://settings.cfg (IndexedDB on the web build).

signal changed

const PATH := "user://settings.cfg"
const RENDER_HEIGHTS := [180, 240, 360, 480]

var look_sensitivity: float = 0.0045   ## radians per UI pixel dragged
var palette: int = 0
var brightness: float = 1.15
var dither_amount: float = 1.0
var contrast: float = 1.25
var render_height: int = 240           ## height of the low-res 3D image
var show_debug: bool = true
var shadows: int = 1              ## 0 off, 1 window light only, 2 window + lantern


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	look_sensitivity = clampf(cfg.get_value("input", "look_sensitivity", look_sensitivity), 0.001, 0.012)
	palette = clampi(cfg.get_value("video", "palette", palette), 0, Palettes.count() - 1)
	brightness = clampf(cfg.get_value("video", "brightness", brightness), 0.5, 2.5)
	dither_amount = clampf(cfg.get_value("video", "dither_amount", dither_amount), 0.0, 1.0)
	contrast = clampf(cfg.get_value("video", "contrast", contrast), 0.8, 2.0)
	render_height = cfg.get_value("video", "render_height", render_height)
	if not RENDER_HEIGHTS.has(render_height):
		render_height = 240
	show_debug = cfg.get_value("debug", "show_debug", show_debug)
	shadows = clampi(int(cfg.get_value("video", "shadows", shadows)), 0, 2)


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("input", "look_sensitivity", look_sensitivity)
	cfg.set_value("video", "palette", palette)
	cfg.set_value("video", "brightness", brightness)
	cfg.set_value("video", "dither_amount", dither_amount)
	cfg.set_value("video", "contrast", contrast)
	cfg.set_value("video", "render_height", render_height)
	cfg.set_value("debug", "show_debug", show_debug)
	cfg.set_value("video", "shadows", shadows)
	cfg.save(PATH)
	changed.emit()


func cycle_palette() -> void:
	palette = (palette + 1) % Palettes.count()
	save()


func cycle_render_height() -> void:
	var i := RENDER_HEIGHTS.find(render_height)
	render_height = RENDER_HEIGHTS[(i + 1) % RENDER_HEIGHTS.size()]
	save()


func cycle_shadows() -> void:
	shadows = (shadows + 1) % 3
	save()
