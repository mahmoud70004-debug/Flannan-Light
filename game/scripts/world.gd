extends Node
## The game world: Martin's flat, the first-person player, the story and the horror director, and the
## render pipeline (3D at a chosen height -> film shader -> screen). Debug aids for look-dev and
## tests: add ?spawn=<spot>&day=<n>&res=<height>&grade=<n>&shadows=<n>&fx=<0-4>&fear=<0-1> to the
## web URL, or pass `-- --spawn=<spot> --day=3` to the Godot command line. A spawn skips the story
## and shows the flat as it is on that day; `spawn=plan` is a top-down view with the ceilings hidden.

const SHADER := preload("res://shaders/film_post.gdshader")
const TITLE := "res://scenes/title.tscn"

var _view: SubViewport
var _root3d: Node3D
var _post_mat: ShaderMaterial
var _player: Player
var _controls: TouchControls
var _hud: Hud
var _apartment: Apartment
var _env: Environment
var _stranger: Stranger
var _director: Director
var _story: Story
var _ambience: Ambience
var _overrides := {}
var _debug_scene := false


func _ready() -> void:
	_read_overrides()
	_debug_scene = _overrides.has("spawn")
	if _overrides.has("day"):
		GameState.day = clampi(int(_overrides["day"]), 1, Days.COUNT)
	_build_view()
	_build_world()
	_build_ui()
	_apply_settings()
	get_viewport().size_changed.connect(_apply_settings)
	Settings.changed.connect(_apply_settings)
	_hud.set_fade(0.0 if _debug_scene else 1.0)
	if _debug_scene:
		_story.show_debug_day()
		return
	_story.start_day()


## Debug arguments from the URL (web) or command line (desktop).
func _read_overrides() -> void:
	if OS.has_feature("web"):
		for key in ["spawn", "day", "res", "grade", "shadows", "msaa", "fx", "fear"]:
			var v := str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('%s') || ''" % key))
			if v != "":
				_overrides[key] = v
	var injected: Dictionary = Engine.get_meta("overrides", {})        # tests pass their own
	for k in injected:
		_overrides[k] = str(injected[k])
	for a in OS.get_cmdline_user_args():
		var kv := (a as String).trim_prefix("--").split("=")
		if kv.size() == 2:
			_overrides[kv[0]] = kv[1]


func _opt(key: String, stored: int) -> int:
	return int(_overrides[key]) if _overrides.has(key) else stored


# --- render pipeline --------------------------------------------------------

func _build_view() -> void:
	_view = SubViewport.new()
	_view.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_view)
	_root3d = Node3D.new()
	_view.add_child(_root3d)

	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	var rect := TextureRect.new()
	rect.texture = _view.get_texture()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_post_mat = ShaderMaterial.new()
	_post_mat.shader = SHADER
	rect.material = _post_mat
	layer.add_child(rect)


func _apply_settings() -> void:
	var vr := get_viewport().get_visible_rect().size
	var h := _opt("res", Settings.render_height)
	_view.size = Vector2i(maxi(int(round(h * vr.x / maxf(vr.y, 1.0))), 16), h)
	var aa := _opt("msaa", Settings.msaa)
	_view.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][aa]
	var shadows := _opt("shadows", Settings.shadows)
	if _apartment:
		_apartment.apply_shadows(shadows)
	Sfx.set_volume(Settings.volume)
	_apply_film()
	if _hud:
		var grade := _opt("grade", Settings.grade)
		_hud.set_info("%s · FX %s · %dp · MSAA %s · shadows %s · day %d · %s" % [Film.grade_name(grade), Film.fx_name(_opt("fx", Settings.fx)), h, ["off", "2x", "4x"][aa], ["off", "hall", "all"][shadows], GameState.day, BuildInfo.label()])


func _apply_film() -> void:
	var fear := float(_overrides["fear"]) if _overrides.has("fear") else (_story.fear if _story else 0.0)
	var amount := Film.fx_amount(_opt("fx", Settings.fx), fear)
	Film.apply(_post_mat, _opt("grade", Settings.grade), Settings.brightness, amount)


# --- 3D world ---------------------------------------------------------------

func _build_world() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color.BLACK
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.20, 0.21, 0.24)
	_env.ambient_light_energy = 0.9
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.tonemap_exposure = 1.0
	_env.fog_enabled = true
	_env.fog_light_color = Color(0.07, 0.075, 0.085)
	_env.fog_density = 0.035
	var world_env := WorldEnvironment.new()
	world_env.environment = _env
	_root3d.add_child(world_env)

	_apartment = Apartment.new()
	_root3d.add_child(_apartment)

	_player = Player.new()
	_root3d.add_child(_player)
	_apartment.viewer = _player
	_player.position = _apartment.spawn_point()
	_player.rotation.y = _apartment.spawn_yaw()

	_stranger = Stranger.new()
	_stranger.player = _player
	_stranger.apartment = _apartment
	_root3d.add_child(_stranger)

	Sfx.world = _root3d
	_ambience = Ambience.new()
	add_child(_ambience)
	_ambience.setup(_apartment)

	_director = Director.new()
	_director.apartment = _apartment
	_director.player = _player
	_director.stranger = _stranger
	add_child(_director)

	_story = Story.new()
	_story.apartment = _apartment
	_story.player = _player
	_story.stranger = _stranger
	_story.director = _director
	_story.ambience = _ambience
	add_child(_story)
	_director.story = _story

	var spot := str(_overrides.get("spawn", ""))
	var spots := _apartment.debug_spots()
	if spots.has(spot):
		_player.position = spots[spot][0]
		_player.rotation.y = spots[spot][1]
		_player.set_pitch(spots[spot][2])
	elif spot == "plan":
		var f := _apartment.footprint()
		_player.position = Vector3((f[0] + f[1]) * 0.5, 15.0, (f[2] + f[3]) * 0.5)
		_player.rotation.y = 0.0
		_player.set_pitch(-PI / 2.0)
		_player.set_physics_process(false)
		_apartment.set_ceilings_visible(false)
		_apartment.show_everything()
		_env.fog_enabled = false


# --- UI ----------------------------------------------------------------------

func _build_ui() -> void:
	_hud = Hud.new()
	add_child(_hud)
	_story.hud = _hud
	var layer := CanvasLayer.new()
	layer.layer = 10
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_controls = TouchControls.new()
	layer.add_child(_controls)
	_story.controls = _controls
	_controls.look.connect(func(rel: Vector2) -> void:
		if not get_tree().paused:
			_player.look_by(rel, Settings.look_sensitivity))
	_controls.interact_pressed.connect(_on_interact)
	_controls.menu_pressed.connect(_toggle_menu)
	_controls.tasks_pressed.connect(func() -> void:
		if _story.is_free():
			_story.show_tasks(5.0))
	_controls.photo_pressed.connect(_story.take_photo)
	_apartment.used.connect(_story.on_used)
	_apartment.said.connect(_hud.say)
	_stranger.vanished.connect(_director.on_stranger_vanished)
	_story.finished.connect(_to_title)
	_hud.doc_closed.connect(func() -> void: pass)


func _on_interact() -> void:
	if not _story.is_free() and not _debug_scene:
		return
	var t := _player.target()
	if t:
		t.call("interact")


func _toggle_menu() -> void:
	if _hud.menu_open:
		_hud.close_menu()
		get_tree().paused = false
		return
	if _hud.card_open or _hud.doc_open:
		return
	get_tree().paused = true
	_open_menu()


func _open_menu() -> void:
	var resume := func() -> void:
		_hud.close_menu()
		get_tree().paused = false
	var rebuild := func(fn: Callable) -> Callable:
		return func() -> void:
			fn.call()
			_open_menu()
	_hud.open_menu([
		{"text": "RESUME", "call": resume},
		{"text": "Look: %s" % Film.grade_name(Settings.grade), "call": rebuild.call(Settings.cycle_grade)},
		{"text": "Pixel filter: %s" % Film.fx_name(Settings.fx), "call": rebuild.call(Settings.cycle_fx)},
		{"text": "Picture height: %dp" % Settings.render_height, "call": rebuild.call(Settings.cycle_render_height)},
		{"text": "Shadows: %s" % ["off", "hall", "all"][Settings.shadows], "call": rebuild.call(Settings.cycle_shadows)},
		{"text": "Anti-aliasing: %s" % ["off", "2x", "4x"][Settings.msaa], "call": rebuild.call(Settings.cycle_msaa)},
		{"text": "Volume: %d%%" % int(round(Settings.volume * 100.0)), "call": rebuild.call(Settings.cycle_volume)},
		{"text": "Debug info: %s" % ("on" if Settings.show_debug else "off"), "call": rebuild.call(Settings.toggle_debug)},
		{"text": "SAVE AND QUIT", "call": func() -> void:
			GameState.save()
			_to_title.call()},
	])


func _to_title() -> void:
	if _overrides.has("no_title"):
		return
	get_tree().paused = false
	Sfx.clear()
	_ambience.stop_all()
	get_tree().change_scene_to_file(TITLE)


func _process(delta: float) -> void:
	_controls.blocked = _hud.doc_open or _hud.card_open or _hud.menu_open
	_controls.lock_move = (_story.busy or _story.locked) and not _debug_scene
	_player.move_input = _controls.move_vector
	var t := _player.target()
	_controls.can_interact = t != null and (_story.is_free() or _debug_scene)
	_hud.set_prompt(str(t.get("prompt")) if (t and (_story.is_free() or _debug_scene) and not _hud.card_open) else "")
	if not _debug_scene:
		_director.update(delta)
	_ambience.update(delta, _story.fear)
	_apply_film()
