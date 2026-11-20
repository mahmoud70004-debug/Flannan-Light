class_name TouchControls
extends Control
## Left side: floating move stick. Right side: drag to look. Round Interact
## button bottom-right. Three small debug buttons top-right. Everything is
## hit-tested here so a thumb never fights the GUI system. WASD/E work on desktop.

signal look(relative: Vector2)
signal interact_pressed
signal menu_pressed
signal filter_pressed
signal resolution_pressed
signal shadows_pressed

const STICK_RADIUS := 110.0
const KNOB_RADIUS := 46.0
const DEADZONE := 0.12
const LEFT_ZONE := 0.4            ## fraction of width where a touch starts the stick
const BUTTON_RADIUS := 82.0

var move_vector := Vector2.ZERO
var can_interact := false

var _stick_index := -1
var _look_index := -1
var _ui_index := -1
var _stick_base := Vector2.ZERO
var _stick_knob := Vector2.ZERO
var _labels := ["MENU", "FILTER", "RES", "SHADOW"]
var _last_pos := {}                ## finger index -> last absolute position (see _drag)
var _use_mouse := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_reset_stick)
	_reset_stick()
	# Real touchscreens deliver touches only. Mouse stands in as one finger on desktops.
	_use_mouse = not DisplayServer.is_touchscreen_available()


func _interact_center() -> Vector2:
	return Vector2(size.x - 150.0, size.y - 170.0)


func _top_button_rect(i: int) -> Rect2:
	return Rect2(size.x - 190.0 * (i + 1), 18.0, 172.0, 66.0)


func _reset_stick() -> void:
	_stick_base = Vector2(190.0, size.y - 190.0)
	_stick_knob = _stick_base
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			_press(event.index, event.position)
		else:
			_release(event.index)
	elif event is InputEventScreenDrag:
		_drag(event.index, event.position)
	elif _use_mouse and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press(-10, event.position)
		else:
			_release(-10)
	elif _use_mouse and event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		_drag(-10, event.position)
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		interact_pressed.emit()


func _press(index: int, pos: Vector2) -> void:
	_last_pos[index] = pos
	if (pos - _interact_center()).length() <= BUTTON_RADIUS:
		_ui_index = index
		interact_pressed.emit()
		return
	for i in 4:
		if _top_button_rect(i).has_point(pos):
			_ui_index = index
			match i:
				0: menu_pressed.emit()
				1: filter_pressed.emit()
				2: resolution_pressed.emit()
				3: shadows_pressed.emit()
			return
	if pos.x < size.x * LEFT_ZONE:
		if _stick_index == -1:
			_stick_index = index
			_stick_base = pos
			_stick_knob = pos
			move_vector = Vector2.ZERO
			queue_redraw()
	elif _look_index == -1:
		_look_index = index


func _drag(index: int, pos: Vector2) -> void:
	# Godot's web build computes ScreenDrag.relative per slot in the event's touch list,
	# not per finger. When only one finger moves, that is the previous position of a
	# *different* finger, so the look jumps by hundreds of pixels. Track positions
	# per finger identifier ourselves and ignore event.relative.
	var relative: Vector2 = pos - _last_pos.get(index, pos)
	_last_pos[index] = pos
	if index == _stick_index:
		var offset := (pos - _stick_base).limit_length(STICK_RADIUS)
		_stick_knob = _stick_base + offset
		var v := offset / STICK_RADIUS
		move_vector = Vector2.ZERO if v.length() < DEADZONE else v
		queue_redraw()
	elif index == _look_index:
		look.emit(relative)


func _release(index: int) -> void:
	_last_pos.erase(index)
	if index == _stick_index:
		_stick_index = -1
		move_vector = Vector2.ZERO
		_reset_stick()
	elif index == _look_index:
		_look_index = -1
	elif index == _ui_index:
		_ui_index = -1


func _process(_delta: float) -> void:
	if _stick_index == -1:
		var k := Vector2(
			Input.get_axis("ui_left", "ui_right") + _key_axis(KEY_A, KEY_D),
			_key_axis(KEY_W, KEY_S) + Input.get_axis("ui_up", "ui_down"))
		move_vector = k.limit_length(1.0)
	queue_redraw()


func _key_axis(neg: Key, pos: Key) -> float:
	return float(Input.is_physical_key_pressed(pos)) - float(Input.is_physical_key_pressed(neg))


func _draw() -> void:
	var line := Color(1, 1, 1, 0.45)
	var fill := Color(1, 1, 1, 0.12)
	draw_circle(_stick_base, STICK_RADIUS, fill)
	draw_arc(_stick_base, STICK_RADIUS, 0.0, TAU, 48, line, 3.0)
	draw_circle(_stick_knob, KNOB_RADIUS, Color(1, 1, 1, 0.3))

	var c := _interact_center()
	var active := Color(1, 1, 1, 0.8) if can_interact else line
	draw_circle(c, BUTTON_RADIUS, Color(1, 1, 1, 0.22 if can_interact else 0.1))
	draw_arc(c, BUTTON_RADIUS, 0.0, TAU, 48, active, 4.0)
	var font := ThemeDB.fallback_font
	draw_string(font, c + Vector2(-60, 12), "USE", HORIZONTAL_ALIGNMENT_CENTER, 120, 34, active)

	for i in 4:
		var r := _top_button_rect(i)
		draw_rect(r, Color(0, 0, 0, 0.45))
		draw_rect(r, line, false, 2.0)
		draw_string(font, r.position + Vector2(0, 44), _labels[i], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 26, Color(1, 1, 1, 0.85))
