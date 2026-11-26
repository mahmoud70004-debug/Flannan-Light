extends Node
## User settings, saved to user://settings.cfg (IndexedDB on the web build).

signal changed

const PATH := "user://settings.cfg"
const RENDER_HEIGHTS := [240, 360, 480, 540]
const VERSION := 4                 ## stored with the file
const LOOK_VERSION := 4            ## look settings and picture height saved before this are discarded (new defaults)
const PALETTE_VERSION := 3         ## palette order changed in v3, so older indexes are discarded

var look_sensitivity: float = 0.0045   ## radians per UI pixel dragged
var palette: int = 0
var look_mode: int = 1             ## 0 = crunch (dithered palette), 1 = photo (many tones, grain, halation)
var brightness: float = 1.15
var dither_amount: float = 0.3
var contrast: float = 1.25
var dither_cell: int = 1          ## size of one dither cell in low-res pixels (1 fine, 2 chunky)
var render_height: int = 360           ## height of the low-res 3D image
var show_debug: bool = true
var shadows: int = 1              ## 0 off, 1 window light only, 2 window + lantern


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	var version: int = cfg.get_value("meta", "version", 1)
	look_sensitivity = clampf(cfg.get_value("input", "look_sensitivity", look_sensitivity), 0.001, 0.012)
	if version >= LOOK_VERSION:
		look_mode = clampi(int(cfg.get_value("video", "look_mode", look_mode)), 0, 1)
	if version >= PALETTE_VERSION:
		palette = clampi(cfg.get_value("video", "palette", palette), 0, Palettes.count() - 1)
	if version >= LOOK_VERSION:
		brightness = clampf(cfg.get_value("video", "brightness", brightness), 0.5, 2.5)
	if version >= LOOK_VERSION:
		dither_amount = clampf(cfg.get_value("video", "dither_amount", dither_amount), 0.0, 1.0)
		dither_cell = clampi(int(cfg.get_value("video", "dither_cell", dither_cell)), 1, 3)
	if version >= LOOK_VERSION:
		contrast = clampf(cfg.get_value("video", "contrast", contrast), 0.8, 2.0)
	if version >= LOOK_VERSION:
		render_height = cfg.get_value("video", "render_height", render_height)
	if not RENDER_HEIGHTS.has(render_height):
		render_height = 360
	show_debug = cfg.get_value("debug", "show_debug", show_debug)
	shadows = clampi(int(cfg.get_value("video", "shadows", shadows)), 0, 2)


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", VERSION)
	cfg.set_value("input", "look_sensitivity", look_sensitivity)
	cfg.set_value("video", "palette", palette)
	cfg.set_value("video", "look_mode", look_mode)
	cfg.set_value("video", "brightness", brightness)
	cfg.set_value("video", "dither_amount", dither_amount)
	cfg.set_value("video", "dither_cell", dither_cell)
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


func toggle_look_mode() -> void:
	look_mode = 1 - look_mode
	save()
