extends Node
## The game world: Martin's flat, the first-person player, and the render pipeline
## (3D at a chosen height -> film shader -> screen). Debug aids for look-dev and
## tests: add ?spawn=<spot>&res=<height>&grade=<n>&shadows=<n>&fx=<0-4>&fear=<0-1> to the web URL,
## or pass `-- --spawn=<spot> --res=<height> --fear=0.5` to the Godot command line.
## `spawn=plan` is a top-down view with the ceilings hidden.

const SHADER := preload("res://shaders/film_post.gdshader")

var _view: SubViewport
var _post_mat: ShaderMaterial
var _player: Player
var _controls: TouchControls
var _hud: Hud
var _apartment: Apartment
var _env: Environment
var _overrides := {}
var _elapsed := 0.0
var _spike := 0.0                 ## a short burst of extra fear (events call boost_fear)
var _next_spike := 25.0
var fear := 0.0                   ## 0..1 story tension; drives the pixel/dither filter in AUTO


func _ready() -> void:
	_read_overrides()
	_build_view()
	_build_world()
	_build_ui()
	_apply_settings()
	get_viewport().size_changed.connect(_apply_settings)
	Settings.changed.connect(_apply_settings)


## Debug arguments from the URL (web) or command line (desktop).
func _read_overrides() -> void:
	if OS.has_feature("web"):
		for key in ["spawn", "res", "grade", "shadows", "msaa", "fx", "fear"]:
			var v := str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('%s') || ''" % key))
			if v != "":
				_overrides[key] = v
	for a in OS.get_cmdline_user_args():
		var kv := (a as String).trim_prefix("--").split("=")
		if kv.size() == 2:
			_overrides[kv[0]] = kv[1]


func _opt(key: String, stored: int) -> int:
	return int(_overrides[key]) if _overrides.has(key) else stored


## Extra fear for a moment (an event, a sound). Decays on its own.
func boost_fear(amount: float) -> void:
	_spike = maxf(_spike, amount)


## Tension over time: a slow rise from 0.12 to about 0.9 over ten minutes, a breathing
## wobble, and now and then a spike. Events add to it with boost_fear().
func _update_fear(delta: float) -> void:
	_elapsed += delta
	_spike = maxf(_spike - delta / 1.6 * 0.35, 0.0)
	if _elapsed >= _next_spike:
		_spike = maxf(_spike, 0.3)
		_next_spike = _elapsed + randf_range(25.0, 55.0)
	var base := 0.12 + 0.78 * smoothstep(0.0, 600.0, _elapsed)
	fear = clampf(base + 0.05 * sin(_elapsed * 0.6) + _spike, 0.0, 1.0)
	if _overrides.has("fear"):
		fear = clampf(float(_overrides["fear"]), 0.0, 1.0)


# --- render pipeline --------------------------------------------------------

func _build_view() -> void:
	_view = SubViewport.new()
	_view.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_view)

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
	_apply_film()
	if _hud:
		var grade := _opt("grade", Settings.grade)
		_hud.set_info("%s · FX %s · %dp · MSAA %s · shadows %s · %s" % [Film.grade_name(grade), Film.fx_name(_opt("fx", Settings.fx)), h, ["off", "2x", "4x"][aa], ["off", "hall", "all"][shadows], BuildInfo.label()])


func _apply_film() -> void:
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
	_view.add_child(world_env)

	_apartment = Apartment.new()
	_view.add_child(_apartment)
	_apartment.said.connect(func(t: String) -> void: _hud.say(t))

	_player = Player.new()
	_view.add_child(_player)
	_apartment.viewer = _player
	_player.position = _apartment.spawn_point()
	_player.rotation.y = _apartment.spawn_yaw()
	var spot := str(_overrides.get("spawn", ""))
	var spots := _apartment.debug_spots()
	if spots.has(spot):
		_player.position = spots[spot][0]
		_player.rotation.y = spots[spot][1]
		_player.set_pitch(spots[spot][2])
	elif spot == "plan":
		_player.position = Vector3(-0.8, 15.0, -5.0)
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
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_controls = TouchControls.new()
	layer.add_child(_controls)
	_controls.look.connect(func(rel: Vector2) -> void: _player.look_by(rel, Settings.look_sensitivity))
	_controls.interact_pressed.connect(_on_interact)
	_controls.menu_pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/title.tscn"))
	_controls.grade_pressed.connect(Settings.cycle_grade)
	_controls.resolution_pressed.connect(Settings.cycle_render_height)
	_controls.shadows_pressed.connect(Settings.cycle_shadows)
	_controls.fx_pressed.connect(Settings.cycle_fx)


func _on_interact() -> void:
	var t := _player.target()
	if t:
		t.call("interact")


func _process(delta: float) -> void:
	_update_fear(delta)
	_apply_film()
	_player.move_input = _controls.move_vector
	var t := _player.target()
	_controls.can_interact = t != null
	_hud.set_prompt(str(t.get("prompt")) if t else "")
