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
var _weather: WeatherSound
var _indoors := false


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
	_post_mat.set_shader_parameter("rain", 0.0 if _indoors else float(Atmosphere.PRESETS[_time].get("rain", 0.0)))
	_post_mat.set_shader_parameter("grain", 0.05)
	_post_mat.set_shader_parameter("halation", 0.7)
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
	_lighthouse.rotation.y = _island.tower_yaw()             # the door faces the landing
	_view.add_child(_lighthouse)
	_island.cut_terrain(_lighthouse.global_transform, Lighthouse.TERRAIN_HOLE)

	_time = "day"
	var t := arg("time")
	if Atmosphere.NAMES.has(t):
		_time = t
	_vignette = Atmosphere.apply(_time, _env, _sun, _island, _lighthouse)

	Sfx.world = _island
	_weather = WeatherSound.new()
	_weather.rain = float(Atmosphere.PRESETS[_time].get("rain", 0.0))
	add_child(_weather)

	_player = Player.new()
	_spawn = _island.spawn_point()
	_view.add_child(_player)
	_player.position = _spawn
	_player.rotation.y = _island.spawn_yaw()        # facing the island
	_safe = _spawn
	_debug_spawn()


## A debug option: `?name=value` on the web build, or `-- --name=value` on the command line (screenshots, tests).
static func arg(name: String) -> String:
	if OS.has_feature("web"):
		return str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('%s') || ''" % name))
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % name):
			return a.substr(name.length() + 3)
	return ""


## Debug aid: spawn=<view> on the URL or the command line (screenshots, tests). Views:
## dock, stair, gate, door, tower_look, inside, stairs, store, shed, bedroom, top, gallery, pier_top, sky.
func _debug_spawn() -> void:
	var where := arg("spawn")
	var lh := _lighthouse
	var L := func(x: float, y: float, z: float) -> Vector3: return lh.to_global(Vector3(x, y, z))
	var walk := _island.walk_points()
	var up := Vector3(0, 0.1, 0)
	match where:
		"dock":
			_put(walk[1] + up + _island.seaward() * 1.5, walk[3])
		"stair":
			_put(walk[2] + up, walk[4] + Vector3(0, 1.5, 0))
		"gate":
			_put(walk[walk.size() - 1] + up, lh.to_global(Vector3(0, 2.0, 0)))
		"door":
			_put(L.call(0.0, 0.1, Lighthouse.R_BASE + 2.4), L.call(0.0, 1.6, 0.0))
		"tower_look":                                   # the first reference: the tower from below its door, looking up
			_put(L.call(-2.5, 0.1, 9.5), L.call(0.0, 11.0, 0.0))
		"inside":
			_put(L.call(0.3, 0.1, 2.0), L.call(0.0, 1.3, -2.7))
		"stairs":
			var a := Lighthouse.stair_angle(30.0)
			_put(lh.to_global(MeshBuilder.polar(a, 2.25, Lighthouse.stair_y(30.0) + 0.15)),
					lh.to_global(MeshBuilder.polar(a - 60.0, 2.25, Lighthouse.stair_y(90.0) + 1.6)))
		"store":
			_put(L.call(Lighthouse.SHED_STAIR_X, Lighthouse.STORE_FLOOR_Y + 0.1, Lighthouse.STORE_FRONT_Z - 0.9),
					L.call(Lighthouse.SHED_STAIR_X - 1.0, Lighthouse.STORE_FLOOR_Y + 1.0, Lighthouse.STORE_FRONT_Z - 4.5))
		"shed":
			_put(L.call(2.2, 0.1, 0.0), L.call(Lighthouse.SHED_STAIR_X, -1.5, -3.5))
		"bedroom":
			_put(L.call(0.2, 0.1, -3.3), L.call(-0.8, 0.6, -5.6))
		"top":
			_put(L.call(-1.9, Lighthouse.TOP_Y + 0.1, -1.2), L.call(0.0, Lighthouse.TOP_Y + 1.8, 0.0))
		"gallery":
			_put(lh.to_global(MeshBuilder.polar(-80.0, 3.5, Lighthouse.TOP_Y + 0.1)), walk[0])
		"pier_top":                                     # the second reference: the top of the stair, looking down to the sea
			_put(walk[walk.size() - 2] + up, walk[0], -0.42)
		"sky":
			_player.position = _lighthouse.position + Vector3(40.0, 70.0, 80.0)
			_player.rotation.y = 0.5
			_player.look_by(Vector2(0, 700.0), 0.001)
			_player.set_physics_process(false)
			_env.fog_enabled = false
	if where != "":
		_spawn = _player.position
		_safe = _spawn


func _put(pos: Vector3, target: Vector3, pitch := 999.0) -> void:
	_player.position = pos
	var d := target - (pos + Vector3(0, 1.6, 0))
	_player.rotation.y = atan2(-d.x, -d.z)
	_player.set_pitch(pitch if pitch != 999.0 else atan2(d.y, Vector2(d.x, d.z).length()))


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
	# The hand lantern is lit at night and below ground (the store has no light of its own).
	var rel := _player.global_position - _lighthouse.position
	var underground := Vector2(rel.x, rel.z).length() < 16.0 and rel.y < -1.2
	var want_lantern := _time == "night" or underground
	_weather.underground = underground
	var indoors := underground or _lighthouse.is_indoors(_player.global_position)
	if indoors != _indoors:
		_indoors = indoors
		_post_mat.set_shader_parameter("rain", 0.0 if indoors else float(Atmosphere.PRESETS[_time].get("rain", 0.0)))
	if want_lantern != _player.lantern_on():
		_player.set_lantern(want_lantern)
	_island.update_sky(_player.camera.global_position, _lighthouse.lantern_world())
	var t := _player.target()
	_controls.can_interact = t != null
	_hud.set_prompt(str(t.get("prompt")) if t else "")
	if _player.is_on_floor() and _player.position.y > 0.3:
		_safe = _player.position
	if _player.position.y < -1.5:                    # fell off the rocks into the sea: back to the last dry spot
		_player.position = _safe
		_player.velocity = Vector3.ZERO
