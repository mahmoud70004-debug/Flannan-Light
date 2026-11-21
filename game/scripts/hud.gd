class_name Hud
extends CanvasLayer
## Debug readout, interaction prompt and crosshair. Drawn over the dithered
## image at full resolution.

var _debug: Label
var _prompt: Label
var _cross: Control
var _fps_avg := 0.0
var _worst_ms := 0.0
var _worst_window := 0.0
var _info := ""
var _line: Label
var _line_tween: Tween


func _ready() -> void:
	layer = 5
	_debug = Label.new()
	_debug.position = Vector2(20, 14)
	_debug.add_theme_font_size_override("font_size", 22)
	_debug.add_theme_color_override("font_outline_color", Color.BLACK)
	_debug.add_theme_constant_override("outline_size", 6)
	add_child(_debug)

	_prompt = Label.new()
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -250
	_prompt.offset_left = -300
	_prompt.offset_right = 300
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 30)
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 8)
	add_child(_prompt)

	_line = Label.new()
	_line.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_line.offset_top = -120
	_line.offset_left = -520
	_line.offset_right = 520
	_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.add_theme_font_size_override("font_size", 32)
	_line.add_theme_color_override("font_outline_color", Color.BLACK)
	_line.add_theme_constant_override("outline_size", 10)
	_line.modulate.a = 0.0
	add_child(_line)

	_cross = Control.new()
	_cross.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cross.draw.connect(func() -> void:
		_cross.draw_circle(_cross.size * 0.5, 3.0, Color(1, 1, 1, 0.7)))
	add_child(_cross)


func set_info(text: String) -> void:
	_info = text


## Martin's inner voice: a short line that fades in, stays, and fades out.
func say(text: String, seconds := 3.2) -> void:
	_line.text = text
	if _line_tween:
		_line_tween.kill()
	_line_tween = create_tween()
	_line_tween.tween_property(_line, "modulate:a", 1.0, 0.4)
	_line_tween.tween_interval(seconds)
	_line_tween.tween_property(_line, "modulate:a", 0.0, 0.8)


func set_prompt(text: String) -> void:
	_prompt.text = text


func _process(delta: float) -> void:
	_debug.visible = Settings.show_debug
	_worst_window += delta
	_worst_ms = maxf(_worst_ms, delta * 1000.0)
	_fps_avg = lerpf(_fps_avg, 1.0 / maxf(delta, 0.0001), 0.05)
	if _worst_window >= 5.0:
		_worst_window = 0.0
		_worst_ms = delta * 1000.0
	var calls := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var tris := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	_debug.text = "%.0f fps · worst %.0f ms/5s\ndraw calls %d · tris %d\n%s" % [_fps_avg, _worst_ms, calls, tris, _info]
