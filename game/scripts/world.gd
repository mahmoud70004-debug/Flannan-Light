extends Node
## Phase 0 test island: a grey-box yard with a lighthouse beam, one switch,
## and the full render pipeline (low-res 3D -> dither shader -> screen).

const SHADER := preload("res://shaders/dither_palette.gdshader")

var _view: SubViewport
var _post_mat: ShaderMaterial
var _player: Player
var _controls: TouchControls
var _hud: Hud
var _room: StoreRoom
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
	if _room:
		_room.apply_shadows(Settings.shadows)
	if _hud:
		_hud.set_info("%s · %s · %dp · shadows %s · %s" % [Palettes.preset_name(Settings.palette), _time, h, ["off", "window", "window+lantern"][Settings.shadows], BuildInfo.label()])


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

	_room = StoreRoom.new()
	_room.position = _island.hut_position()
	_view.add_child(_room)

	_time = "day"
	if OS.has_feature("web"):
		var t := str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('time') || ''"))
		if Atmosphere.NAMES.has(t):
			_time = t
	_vignette = Atmosphere.apply(_time, _env, _sun, _island, _room)

	_player = Player.new()
	_spawn = _island.spawn_point()
	_view.add_child(_player)
	_player.position = _spawn
	_player.look_by(Vector2(0.0, -130.0), 0.001)    # tilt up a little: the tower stands above the ramp
	_debug_spawn()


## Web debug aid: add ?spawn=door (or ?spawn=top) to the URL to start near that spot.
func _debug_spawn() -> void:
	if not OS.has_feature("web"):
		return
	var where := str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('spawn') || ''"))
	match where:
		"door":
			_player.position = _island.hut_position() + Vector3(1.6, 0.1, 4.5)
		"top":
			_player.position = Vector3(0, Island.PLATEAU + 0.1, 6.0)
		"far":
			_player.position = Vector3(-6.0, Island.PLATEAU + 0.1, 12.0)
			_player.look_by(Vector2(675.0, -60.0), 0.001)
		"inside":
			_player.position = _island.hut_position() + Vector3(0.2, 0.1, 1.7)
		"sky":
			_player.position = Vector3(0, 75.0, 75.0)
			_player.look_by(Vector2(0, 800.0), 0.001)
			_player.set_physics_process(false)
			_env.fog_enabled = false
	if where != "":
		_spawn = _player.position


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


func _on_interact() -> void:
	var t := _player.target()
	if t:
		t.call("interact")


func _process(delta: float) -> void:
	_player.move_input = _controls.move_vector
	var t := _player.target()
	_controls.can_interact = t != null
	_hud.set_prompt(str(t.get("prompt")) if t else "")
	if _player.position.y < -4.0:
		_player.position = _spawn
		_player.velocity = Vector3.ZERO
