extends Control
## Title screen: Start, look selection, brightness, sensitivity, build label.
## The Start press is the user gesture the web build needs for audio,
## fullscreen and orientation lock.

var _palette_label: Label
var _swatches: HBoxContainer


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# The menu scrolls, so adding options never pushes the last ones off a short screen.
	var scroll := ScrollContainer.new()
	scroll.anchor_left = 0.5
	scroll.anchor_right = 0.5
	scroll.anchor_top = 0.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = -380
	scroll.offset_right = 380
	scroll.offset_top = 8
	scroll.offset_bottom = -8
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	scroll.add_child(box)

	box.add_child(_label("FLANNAN LIGHT", 58, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_label("Pottsfield Studio", 22, HORIZONTAL_ALIGNMENT_CENTER, 0.55))

	var start := _button("START")
	start.pressed.connect(_on_start)
	box.add_child(start)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var prev := _button("<", 90)
	prev.pressed.connect(func() -> void: _step_palette(-1))
	var next := _button(">", 90)
	next.pressed.connect(func() -> void: _step_palette(1))
	_palette_label = _label("", 34, HORIZONTAL_ALIGNMENT_CENTER)
	_palette_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_palette_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(prev)
	row.add_child(_palette_label)
	row.add_child(next)
	box.add_child(row)

	_swatches = HBoxContainer.new()
	_swatches.alignment = BoxContainer.ALIGNMENT_CENTER
	_swatches.add_theme_constant_override("separation", 0)
	box.add_child(_swatches)

	box.add_child(_slider("Brightness", 0.5, 2.5, Settings.brightness, func(v: float) -> void: Settings.brightness = v))
	box.add_child(_slider("Contrast", 0.8, 2.0, Settings.contrast, func(v: float) -> void: Settings.contrast = v))
	var style := _button("Style: %s" % ["CRUNCH (dither)", "PHOTO (film)"][Settings.look_mode])
	style.custom_minimum_size = Vector2(0, 56)
	style.add_theme_font_size_override("font_size", 26)
	style.pressed.connect(func() -> void:
		Settings.toggle_look_mode()
		style.text = "Style: %s" % ["CRUNCH (dither)", "PHOTO (film)"][Settings.look_mode])
	box.add_child(style)
	box.add_child(_cell_toggle())
	box.add_child(_slider("Dither", 0.0, 1.0, Settings.dither_amount, func(v: float) -> void: Settings.dither_amount = v))
	box.add_child(_slider("Look sensitivity", 0.001, 0.012, Settings.look_sensitivity, func(v: float) -> void: Settings.look_sensitivity = v))

	var build := _label(BuildInfo.label(), 20, HORIZONTAL_ALIGNMENT_RIGHT, 0.5)
	build.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	build.offset_left = -500
	build.offset_top = -44
	build.offset_right = -16
	build.offset_bottom = -8
	add_child(build)

	_refresh_palette()


func _label(text: String, font_size: int, align: HorizontalAlignment, alpha := 1.0) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", font_size)
	l.modulate = Color(1, 1, 1, alpha)
	return l


func _button(text: String, min_w := 0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, 72)
	b.add_theme_font_size_override("font_size", 36)
	return b


func _slider(title: String, lo: float, hi: float, value: float, setter: Callable) -> Control:
	var col := VBoxContainer.new()
	col.add_child(_label(title, 20, HORIZONTAL_ALIGNMENT_LEFT, 0.8))
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = (hi - lo) / 100.0
	s.value = value
	s.custom_minimum_size = Vector2(0, 36)
	s.value_changed.connect(func(v: float) -> void:
		setter.call(v)
		Settings.save())
	col.add_child(s)
	return col


func _cell_toggle() -> Control:
	var b := _button("Dither grain: %s" % ["fine", "chunky", "coarse"][Settings.dither_cell - 1])
	b.custom_minimum_size = Vector2(0, 56)
	b.add_theme_font_size_override("font_size", 26)
	b.pressed.connect(func() -> void:
		Settings.dither_cell = Settings.dither_cell % 3 + 1
		Settings.save()
		b.text = "Dither grain: %s" % ["fine", "chunky", "coarse"][Settings.dither_cell - 1])
	return b


func _step_palette(dir: int) -> void:
	Settings.palette = posmod(Settings.palette + dir, Palettes.count())
	Settings.save()
	_refresh_palette()


func _refresh_palette() -> void:
	_palette_label.text = "Look: %s" % Palettes.preset_name(Settings.palette)
	for c in _swatches.get_children():
		c.queue_free()
	for col: Color in Palettes.colors(Settings.palette):
		var r := ColorRect.new()
		r.color = col
		r.custom_minimum_size = Vector2(70, 26)
		_swatches.add_child(r)


func _on_start() -> void:
	if OS.has_feature("web"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		JavaScriptBridge.eval("try{screen.orientation.lock('landscape').catch(function(){})}catch(e){}")
	get_tree().change_scene_to_file("res://scenes/world.tscn")
