class_name Hud
extends CanvasLayer
## Everything drawn over the game at full resolution: the debug read-out, interaction prompt,
## crosshair, Martin's inner voice and voicemail captions, the task note, the document panel,
## fades, day cards and the pause menu. Coroutines (card, fade, show_doc) can be awaited.

signal doc_closed
signal menu_requested

var doc_open := false
var menu_open := false
var card_open := false

var _debug: Label
var _prompt: Label
var _line: Label
var _caption: Label
var _cross: Control
var _fps_avg := 0.0
var _worst_ms := 0.0
var _worst_window := 0.0
var _info := ""
var _line_tween: Tween
var _objective: Control
var _obj_text: Label
var _obj_tween: Tween
var _obj_target := ""                 ## what the objective is meant to say right now ("" = hidden), whatever the fade is doing
var _note: PanelContainer
var _note_label: RichTextLabel
var _note_tween: Tween
var _doc: Control
var _doc_title: Label
var _doc_body: Label
var _doc_scroll: ScrollContainer
var _fade: ColorRect
var _flash: ColorRect
var _card: Control
var _card_label: Label
var _menu: Control
var _queue: Array = []
var _saying := false


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	_debug = _make_label(22, Vector2(20, 14))
	add_child(_debug)

	_prompt = _make_label(30, Vector2.ZERO)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -250
	_prompt.offset_left = -300
	_prompt.offset_right = 300
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_prompt)

	_line = _make_label(32, Vector2.ZERO)
	_line.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_line.offset_top = -150
	_line.offset_left = -560
	_line.offset_right = 560
	_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.modulate.a = 0.0
	add_child(_line)

	_caption = _make_label(30, Vector2.ZERO)
	_caption.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_caption.offset_top = 120
	_caption.offset_left = -560
	_caption.offset_right = 560
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	_caption.modulate.a = 0.0
	add_child(_caption)

	_cross = Control.new()
	_cross.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cross.draw.connect(func() -> void:
		_cross.draw_circle(_cross.size * 0.5, 3.0, Color(1, 1, 1, 0.7)))
	add_child(_cross)

	_build_objective()
	_build_note()
	_build_doc()
	_build_menu()

	_flash = ColorRect.new()
	_flash.color = Color.WHITE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.modulate.a = 0.0
	add_child(_flash)

	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	add_child(_fade)

	_card = Control.new()
	_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.visible = false
	_card_label = Label.new()
	_card_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card_label.offset_left = 120
	_card_label.offset_right = -120
	_card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_card_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_label.add_theme_font_size_override("font_size", 40)
	_card.add_child(_card_label)
	add_child(_card)


func _make_label(size: int, pos: Vector2) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8 if size >= 28 else 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# --- text lines -------------------------------------------------------------------------------

func set_info(text: String) -> void:
	_info = text


func set_prompt(text: String) -> void:
	_prompt.text = text


## One line of Martin's inner voice; lines say()'d in a row play one after another.
func say(text: String, seconds := -1.0) -> void:
	if seconds < 0.0:
		seconds = 1.5 + 0.05 * text.length()
	_queue.append([text, seconds])
	if not _saying:
		_play_queue()


func say_all(lines: Array) -> void:
	for l in lines:
		say(l)


## Waits until every queued line has been shown.
func wait_lines() -> void:
	while _saying or not _queue.is_empty():
		await get_tree().process_frame


func _play_queue() -> void:
	_saying = true
	while not _queue.is_empty():
		var item: Array = _queue.pop_front()
		_line.text = item[0]
		if _line_tween:
			_line_tween.kill()
		_line_tween = create_tween()
		_line_tween.tween_property(_line, "modulate:a", 1.0, 0.35)
		_line_tween.tween_interval(item[1])
		_line_tween.tween_property(_line, "modulate:a", 0.0, 0.5)
		await _line_tween.finished
	_saying = false


## A voicemail caption (a different colour, at the top).
func caption(text: String, seconds: float) -> void:
	_caption.text = text
	var tw := create_tween()
	tw.tween_property(_caption, "modulate:a", 1.0, 0.2)
	tw.tween_interval(maxf(seconds - 0.2, 0.1))
	tw.tween_property(_caption, "modulate:a", 0.0, 0.3)


# --- task note ------------------------------------------------------------------------------------

func _build_objective() -> void:
	_objective = VBoxContainer.new()
	_objective.position = Vector2(26, 18)
	_objective.custom_minimum_size = Vector2(620, 0)
	_objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var head := _make_label(17, Vector2.ZERO)
	head.text = "OBJECTIVE"
	head.add_theme_color_override("font_color", Color(0.72, 0.62, 0.45))
	_obj_text = _make_label(27, Vector2.ZERO)
	_obj_text.add_theme_color_override("font_color", Color(0.95, 0.93, 0.86))
	_obj_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_obj_text.custom_minimum_size = Vector2(620, 0)
	_objective.add_child(head)
	_objective.add_child(_obj_text)
	_objective.modulate.a = 0.0
	add_child(_objective)


## The current objective, top left. An empty text hides it (a quiet stretch between tasks).
func set_objective(text: String) -> void:
	_obj_target = text
	if _obj_tween:
		_obj_tween.kill()
	if text == "":
		_obj_tween = create_tween()
		_obj_tween.tween_property(_objective, "modulate:a", 0.0, 0.6)
		return
	if _obj_text.text != text or _objective.modulate.a < 0.5:
		_obj_text.text = text
		_objective.modulate.a = 0.0
	_obj_tween = create_tween()
	_obj_tween.tween_property(_objective, "modulate:a", 1.0, 0.8)


func objective_text() -> String:
	return _obj_target


## True while a line of Martin's is on screen or waiting.
func is_talking() -> bool:
	return _saying or not _queue.is_empty()


func _build_note() -> void:
	_note = PanelContainer.new()
	_note.position = Vector2(20, 110)
	_note.custom_minimum_size = Vector2(420, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.86, 0.82, 0.68, 0.94)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 14
	_note.add_theme_stylebox_override("panel", sb)
	_note_label = RichTextLabel.new()
	_note_label.bbcode_enabled = true
	_note_label.fit_content = true
	_note_label.scroll_active = false
	_note_label.custom_minimum_size = Vector2(380, 0)
	_note_label.add_theme_color_override("default_color", Color(0.12, 0.1, 0.08))
	_note_label.add_theme_font_size_override("normal_font_size", 26)
	_note_label.add_theme_font_size_override("bold_font_size", 28)
	_note.add_child(_note_label)
	_note.modulate.a = 0.0
	_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_note_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_note)


## Shows Martin's list for the day. `tasks`: [{text, done}]. Fades out after `seconds` (0 = stay).
func show_tasks(title: String, tasks: Array, seconds := 6.0) -> void:
	var t := "[b]%s[/b]\n" % title
	for task in tasks:
		t += "%s %s\n" % ["[color=#2a5a2a]x[/color]" if task["done"] else "[ ]", ("[s]%s[/s]" % task["text"]) if task["done"] else task["text"]]
	_note_label.text = t
	if _note_tween:
		_note_tween.kill()
	_note_tween = create_tween()
	_note_tween.tween_property(_note, "modulate:a", 1.0, 0.25)
	if seconds > 0.0:
		_note_tween.tween_interval(seconds)
		_note_tween.tween_property(_note, "modulate:a", 0.0, 0.6)


func hide_tasks() -> void:
	if _note_tween:
		_note_tween.kill()
	_note.modulate.a = 0.0


func tasks_visible() -> bool:
	return _note.modulate.a > 0.5


# --- documents ----------------------------------------------------------------------------------------

func _build_doc() -> void:
	_doc = Control.new()
	_doc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_doc.visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_doc.add_child(dim)
	var paper := PanelContainer.new()
	paper.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	paper.custom_minimum_size = Vector2(900, 560)
	paper.offset_left = -450
	paper.offset_right = 450
	paper.offset_top = -300
	paper.offset_bottom = 300
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.9, 0.87, 0.78)
	sb.content_margin_left = 34
	sb.content_margin_right = 34
	sb.content_margin_top = 24
	sb.content_margin_bottom = 24
	paper.add_theme_stylebox_override("panel", sb)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	paper.add_child(col)
	_doc_title = Label.new()
	_doc_title.add_theme_font_size_override("font_size", 34)
	_doc_title.add_theme_color_override("font_color", Color(0.1, 0.08, 0.06))
	col.add_child(_doc_title)
	_doc_scroll = ScrollContainer.new()
	_doc_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_doc_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(_doc_scroll)
	_doc_body = Label.new()
	_doc_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_doc_body.custom_minimum_size = Vector2(800, 0)
	_doc_body.add_theme_font_size_override("font_size", 26)
	_doc_body.add_theme_color_override("font_color", Color(0.14, 0.12, 0.1))
	_doc_scroll.add_child(_doc_body)
	var close := Button.new()
	close.text = "PUT IT DOWN"
	close.custom_minimum_size = Vector2(0, 64)
	close.add_theme_font_size_override("font_size", 28)
	close.pressed.connect(close_doc)
	col.add_child(close)
	_doc.add_child(paper)
	add_child(_doc)


func show_doc(title: String, body: String) -> void:
	_doc_title.text = title
	_doc_body.text = body
	_doc_scroll.scroll_vertical = 0
	_doc.visible = true
	doc_open = true


func close_doc() -> void:
	if not doc_open:
		return
	_doc.visible = false
	doc_open = false
	doc_closed.emit()


## Shows a document and waits until it is put down.
func read_doc(title: String, body: String) -> void:
	show_doc(title, body)
	await doc_closed


# --- fades, flashes, cards ------------------------------------------------------------------------------

func fade(to: float, seconds := 1.0) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", to, seconds)
	await tw.finished


func set_fade(a: float) -> void:
	_fade.modulate.a = a


func fade_color(c: Color) -> void:
	_fade.color = c


func flash(seconds := 0.35) -> void:
	_flash.modulate.a = 0.9
	var tw := create_tween()
	tw.tween_property(_flash, "modulate:a", 0.0, seconds)


## A black card with lines that fade in one after another, then everything fades out.
func card(lines: Array, per_line := 2.2) -> void:
	card_open = true
	_fade.modulate.a = 1.0
	_card.visible = true
	_card_label.text = ""
	var shown := ""
	for i in lines.size():
		shown += ("\n\n" if i > 0 else "") + str(lines[i])
		_card_label.text = shown
		_card_label.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(_card_label, "modulate:a", 1.0, 0.8)
		await tw.finished
		await get_tree().create_timer(per_line).timeout
	var out := create_tween()
	out.tween_property(_card_label, "modulate:a", 0.0, 0.8)
	await out.finished
	_card.visible = false
	card_open = false


# --- pause menu -------------------------------------------------------------------------------------------

func _build_menu() -> void:
	_menu = Control.new()
	_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu.visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu.add_child(dim)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	scroll.offset_left = -330
	scroll.offset_right = 330
	scroll.offset_top = -330
	scroll.offset_bottom = 330
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_menu.add_child(scroll)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.custom_minimum_size = Vector2(640, 0)
	box.add_theme_constant_override("separation", 10)
	scroll.add_child(box)
	add_child(_menu)


## Rebuilds the pause menu rows. `entries`: [{text, call}] (call: Callable run when pressed).
func open_menu(entries: Array) -> void:
	var box := _menu.find_child("Box", true, false)
	for c in box.get_children():
		c.queue_free()
	for e in entries:
		var b := Button.new()
		b.text = e["text"]
		b.custom_minimum_size = Vector2(0, 68)
		b.add_theme_font_size_override("font_size", 30)
		var cb: Callable = e["call"]
		b.pressed.connect(func() -> void:
			cb.call()
			if e.get("refresh", false):
				b.text = e["text_fn"].call())
		box.add_child(b)
	_menu.visible = true
	menu_open = true


func close_menu() -> void:
	_menu.visible = false
	menu_open = false


func _process(delta: float) -> void:
	_debug.visible = Settings.show_debug
	_worst_window += delta
	_worst_ms = maxf(_worst_ms, delta * 1000.0)
	_fps_avg = lerpf(_fps_avg, 1.0 / maxf(delta, 0.0001), 0.05)
	if _worst_window >= 5.0:
		_worst_window = 0.0
		_worst_ms = delta * 1000.0
	if Settings.show_debug:
		var calls := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		var tris := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		_debug.text = "%.0f fps · worst %.0f ms/5s\ndraw calls %d · tris %d\n%s" % [_fps_avg, _worst_ms, calls, tris, _info]
