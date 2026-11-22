extends Control
## Title screen: Start, picture options, sensitivity, build label.
## The Start press is the user gesture the web build needs for audio,
## fullscreen and orientation lock.

const GAME_TITLE := "NO ONE HOME"

var _grade_label: Label


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

	box.add_child(_label(GAME_TITLE, 64, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_label("Pottsfield Studio", 22, HORIZONTAL_ALIGNMENT_CENTER, 0.55))

	var start := _button("START")
	start.pressed.connect(_on_start)
	box.add_child(start)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var prev := _button("<", 90)
	prev.pressed.connect(func() -> void: _step_grade(-1))
	var next := _button(">", 90)
	next.pressed.connect(func() -> void: _step_grade(1))
	_grade_label = _label("", 34, HORIZONTAL_ALIGNMENT_CENTER)
	_grade_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grade_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(prev)
	row.add_child(_grade_label)
	row.add_child(next)
	box.add_child(row)

	box.add_child(_slider("Brightness", 0.6, 1.8, Settings.brightness, func(v: float) -> void: Settings.brightness = v))
	box.add_child(_slider("Look sensitivity", 0.001, 0.012, Settings.look_sensitivity, func(v: float) -> void: Settings.look_sensitivity = v))
	var fx := _button("Pixel filter: %s" % Film.fx_name(Settings.fx))
	fx.custom_minimum_size = Vector2(0, 56)
	fx.add_theme_font_size_override("font_size", 26)
	fx.pressed.connect(func() -> void:
		Settings.cycle_fx()
		fx.text = "Pixel filter: %s" % Film.fx_name(Settings.fx))
	box.add_child(fx)
	var aa := _button("Anti-aliasing: %s" % ["off", "2x", "4x"][Settings.msaa])
	aa.custom_minimum_size = Vector2(0, 56)
	aa.add_theme_font_size_override("font_size", 26)
	aa.pressed.connect(func() -> void:
		Settings.cycle_msaa()
		aa.text = "Anti-aliasing: %s" % ["off", "2x", "4x"][Settings.msaa])
	box.add_child(aa)
	var res := _button("Picture height: %dp" % Settings.render_height)
	res.custom_minimum_size = Vector2(0, 56)
	res.add_theme_font_size_override("font_size", 26)
	res.pressed.connect(func() -> void:
		Settings.cycle_render_height()
		res.text = "Picture height: %dp" % Settings.render_height)
	box.add_child(res)

	var build := _label(BuildInfo.label(), 20, HORIZONTAL_ALIGNMENT_RIGHT, 0.5)
	build.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	build.offset_left = -500
	build.offset_top = -44
	build.offset_right = -16
	build.offset_bottom = -8
	add_child(build)

	_refresh_grade()


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


func _step_grade(dir: int) -> void:
	Settings.grade = posmod(Settings.grade + dir, Film.GRADES.size())
	Settings.save()
	_refresh_grade()


func _refresh_grade() -> void:
	_grade_label.text = "Look: %s" % Film.grade_name(Settings.grade)


func _on_start() -> void:
	if OS.has_feature("web"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		JavaScriptBridge.eval("try{screen.orientation.lock('landscape').catch(function(){})}catch(e){}")
	get_tree().change_scene_to_file("res://scenes/world.tscn")
