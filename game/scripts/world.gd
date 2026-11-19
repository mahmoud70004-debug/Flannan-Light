extends Node
## Phase 0 test island: a grey-box yard with a lighthouse beam, one switch,
## and the full render pipeline (low-res 3D -> dither shader -> screen).

const SHADER := preload("res://shaders/dither_palette.gdshader")

var _view: SubViewport
var _post_mat: ShaderMaterial
var _player: Player
var _controls: TouchControls
var _hud: Hud
var _beam: Node3D
var _lamp: OmniLight3D


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
	if _hud:
		_hud.set_info("%s · %dp · %s" % [Palettes.preset_name(Settings.palette), h, BuildInfo.label()])


# --- 3D world ---------------------------------------------------------------

func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.16, 0.16, 0.18)
	env.fog_enabled = true
	env.fog_light_color = Color.BLACK
	env.fog_density = 0.03
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	_view.add_child(world_env)

	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-55, 30, 0)
	moon.light_energy = 0.35
	_view.add_child(moon)

	var mat_ground := _mat(0.28)
	var mat_wall := _mat(0.55)
	var mat_dark := _mat(0.12)

	_solid(Vector3(80, 1, 80), Vector3(0, -0.5, 0), mat_ground)          # ground
	_solid(Vector3(6, 2.4, 0.3), Vector3(-6, 1.2, 4), mat_wall)           # low walls
	_solid(Vector3(0.3, 2.4, 6), Vector3(-9, 1.2, 7), mat_wall)
	_solid(Vector3(1.2, 1.0, 1.2), Vector3(3, 0.5, 2), mat_dark)          # crates
	_solid(Vector3(1.0, 0.7, 1.0), Vector3(4.4, 0.35, 3.2), mat_wall)
	_solid(Vector3(1.0, 1.4, 1.0), Vector3(-3, 0.7, -3), mat_dark)

	# Lighthouse tower with a rotating beam.
	var tower := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.8
	cyl.bottom_radius = 2.6
	cyl.height = 14.0
	cyl.radial_segments = 12
	tower.mesh = cyl
	tower.material_override = _mat(0.8)
	tower.position = Vector3(0, 7, -16)
	_view.add_child(tower)
	var tower_body := StaticBody3D.new()
	var tower_shape := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 2.4
	cs.height = 14.0
	tower_shape.shape = cs
	tower_body.add_child(tower_shape)
	tower_body.position = tower.position
	_view.add_child(tower_body)

	_beam = Node3D.new()
	_beam.position = Vector3(0, 14.5, -16)
	var spot := SpotLight3D.new()
	spot.spot_range = 70.0
	spot.spot_angle = 14.0
	spot.light_energy = 6.0
	spot.rotation_degrees.x = -4.0
	_beam.add_child(spot)
	_view.add_child(_beam)

	# A switch that toggles a lamp: proves the Interact button and prompt.
	var post := Interactable.new()
	post.prompt = "Lamp"
	post.collision_layer = 1 | 2
	var post_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.3, 1.3, 0.3)
	post_mesh.mesh = box
	post_mesh.material_override = _mat(0.9)
	post.add_child(post_mesh)
	var post_shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = box.size
	post_shape.shape = bs
	post.add_child(post_shape)
	post.position = Vector3(1.5, 0.65, -3.0)
	_view.add_child(post)
	_lamp = OmniLight3D.new()
	_lamp.position = Vector3(1.5, 1.8, -3.0)
	_lamp.omni_range = 8.0
	_lamp.light_energy = 2.0
	_view.add_child(_lamp)
	post.interacted.connect(func() -> void: _lamp.visible = not _lamp.visible)

	_player = Player.new()
	_player.position = Vector3(0, 0.05, 6)
	_view.add_child(_player)


func _mat(grey: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(grey, grey, grey)
	m.roughness = 1.0
	return m


func _solid(size: Vector3, pos: Vector3, mat: Material) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = mat
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)
	_view.add_child(body)


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


func _on_interact() -> void:
	var t := _player.target()
	if t:
		t.interact()


func _process(delta: float) -> void:
	_player.move_input = _controls.move_vector
	_beam.rotate_y(-0.5 * delta)
	var t := _player.target()
	_controls.can_interact = t != null
	_hud.set_prompt(t.prompt if t else "")
