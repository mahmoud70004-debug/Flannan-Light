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
	_post_mat.set_shader_parameter("contrast", Settings.contrast)
	if _room:
		_room.apply_shadows(Settings.shadows)
	if _hud:
		_hud.set_info("%s · %dp · shadows %s · %s" % [Palettes.preset_name(Settings.palette), h, ["off", "window", "window+lantern"][Settings.shadows], BuildInfo.label()])


# --- 3D world ---------------------------------------------------------------

func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.22, 0.22, 0.24)
	env.fog_enabled = true
	env.fog_light_color = Color.BLACK
	env.fog_density = 0.04
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	_view.add_child(world_env)

	_room = StoreRoom.new()
	_view.add_child(_room)

	_player = Player.new()
	_player.position = Vector3(0.2, 0.05, 1.7)
	_view.add_child(_player)


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
		t.interact()


func _process(delta: float) -> void:
	_player.move_input = _controls.move_vector
	var t := _player.target()
	_controls.can_interact = t != null
	_hud.set_prompt(t.prompt if t else "")
