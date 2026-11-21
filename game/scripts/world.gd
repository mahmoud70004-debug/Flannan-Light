extends Node
## Phase 0 test island: a grey-box yard with a lighthouse beam, one switch,
## and the full render pipeline (low-res 3D -> dither shader -> screen).

const SHADER := preload("res://shaders/dither_palette.gdshader")

var _view: SubViewport
var _post_mat: ShaderMaterial
var _player: Player
var _controls: TouchControls
var _hud: Hud
var _lighthouse: Lighthouse
var _safe := Vector3.ZERO
var _island: Island
var _env: Environment
var _sun: DirectionalLight3D
var _time := "day"
var _vignette := 0.3
var _spawn := Vector3.ZERO


func _ready() -> void:
	_build_view()
	_build_world()
	_build_ui()
	_apply_settings()
	get_viewport().size_changed.connect(_apply_settings)
	Settings.changed.connect(_apply_settings)


# --- render pipeline --------------------------------------------------------

func _build_view() -> void:
	_view = SubViewport.new()
	_view.msaa_3d = Viewport.MSAA_DISABLED
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
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_post_mat = ShaderMaterial.new()
	_post_mat.shader = SHADER
	rect.material = _post_mat
	layer.add_child(rect)


func _apply_settings() -> void:
	var vr := get_viewport().get_visible_rect().size
	var h: int = Settings.render_height
	_view.size = Vector2i(maxi(int(round(h * vr.x / maxf(vr.y, 1.0))), 16), h)
	Palettes.apply(_post_mat, Settings.palette)
	_post_mat.set_shader_parameter("brightness", Settings.brightness)
	_post_mat.set_shader_parameter("dither_amount", Settings.dither_amount)
	_post_mat.set_shader_parameter("dither_cell", Settings.dither_cell)
	_post_mat.set_shader_parameter("contrast", Settings.contrast)
	_post_mat.set_shader_parameter("vignette", _vignette)
	_post_mat.set_shader_parameter("mode", Settings.look_mode)
	_post_mat.set_shader_parameter("edge_strength", 0.10 if Settings.look_mode == 1 else 0.8)
	if _lighthouse:
		_lighthouse.apply_shadows(Settings.shadows)
	if _sun:
		_sun.shadow_enabled = Settings.shadows >= 1
		_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		_sun.directional_shadow_max_distance = 80.0
		_sun.shadow_bias = 0.08
		_sun.shadow_normal_bias = 1.2
	if _hud:
		_hud.set_info("%s %s · %s · %dp · shadows %s · %s" % [["CRUNCH", "PHOTO"][Settings.look_mode], Palettes.preset_name(Settings.palette), _time, h, ["off", "sun+window", "sun+window+lantern"][Settings.shadows], BuildInfo.label()])


# --- 3D world ---------------------------------------------------------------

func _build_world() -> void:
	_env = Environment.new()
	var world_env := WorldEnvironment.new()
	world_env.environment = _env
	_view.add_child(world_env)

	_island = Island.new()
	_view.add_child(_island)

	# Sun / moon lights the outdoors (visual layer 1) only; the store room has its own lights.
	_sun = DirectionalLight3D.new()
	_sun.light_cull_mask = 1
	_view.add_child(_sun)

	_lighthouse = Lighthouse.new()
	_lighthouse.position = _island.lighthouse_position()
	_view.add_child(_lighthouse)

	_time = "day"
	if OS.has_feature("web"):
		var t := str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('time') || ''"))
		if Atmosphere.NAMES.has(t):
			_time = t
	_vignette = Atmosphere.apply(_time, _env, _sun, _island, _lighthouse)

	_player = Player.new()
	_spawn = _island.spawn_point()
	_view.add_child(_player)
	_player.position = _spawn
	_player.rotation.y = _island.spawn_yaw()        # facing the island
	_safe = _spawn
	_debug_spawn()


## Web debug aid: add ?spawn=gate|door|inside|stairs|store|far|sky to the URL.
func _debug_spawn() -> void:
	if not OS.has_feature("web"):
		return
	var where := str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('spawn') || ''"))
	var lh := _lighthouse.position
	match where:
		"gate":
			var gp := _island.path_points()
			_player.position = gp[gp.size() - 1] + Vector3(0, 0.2, 3.5)
			var gd: Vector3 = lh - _player.position
			_player.rotation.y = atan2(-gd.x, -gd.z)
		"door":
			_player.position = lh + Vector3(0, 0.1, 11.2)
			_player.rotation.y = 0.0
		"inside":
			_player.position = lh + Vector3(1.0, 0.2, 7.7)
			_player.rotation.y = 0.0
		"stairs":
			_player.position = lh + Vector3(-4.1, 0.2, 4.0)
			_player.rotation.y = PI
		"store":
			_player.position = lh + Vector3(-4.1, Lighthouse.STORE_FLOOR_Y + 0.1, 10.6)
			_player.rotation.y = PI
		"far":
			var pts := _island.path_points()
			_player.position = pts[maxi(pts.size() - 6, 0)] + Vector3(0, 0.1, 0)
			var d := lh - _player.position
			_player.rotation.y = atan2(-d.x, -d.z)
		"sky":
			_player.position = lh + Vector3(40.0, 70.0, 80.0)
			_player.rotation.y = 0.5
			_player.look_by(Vector2(0, 700.0), 0.001)
			_player.set_physics_process(false)
			_env.fog_enabled = false
	if where != "":
		_spawn = _player.position
		_safe = _spawn


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
	_controls.filter_pressed.connect(Settings.cycle_palette)
	_controls.resolution_pressed.connect(Settings.cycle_render_height)
	_controls.shadows_pressed.connect(Settings.cycle_shadows)
	_controls.style_pressed.connect(Settings.toggle_look_mode)


func _on_interact() -> void:
	var t := _player.target()
	if t:
		t.call("interact")


func _process(delta: float) -> void:
	_player.move_input = _controls.move_vector
	var t := _player.target()
	_controls.can_interact = t != null
	_hud.set_prompt(str(t.get("prompt")) if t else "")
	if _player.is_on_floor() and _player.position.y > 0.3:
		_safe = _player.position
	if _player.position.y < -1.5:                    # fell off the rocks into the sea: back to the last dry spot
		_player.position = _safe
		_player.velocity = Vector3.ZERO
