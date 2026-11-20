class_name StoreRoom
extends Node3D
## Look-dev room: the lower store (sacks, barrels, shelves, one lantern, one
## high window). Built from primitives with procedural textures. Used to judge
## lighting, readability and the palette filters on the real phone.

const W := 6.0     ## x size
const D := 5.0     ## z size
const H := 2.8     ## ceiling height

var lantern_light: OmniLight3D
var window_light: SpotLight3D
var _lantern_mat: StandardMaterial3D
var _flicker_t := 0.0
var _lantern_on := true

var _stone: StandardMaterial3D
var _wood: StandardMaterial3D
var _dark_wood: StandardMaterial3D
var _sack: StandardMaterial3D
var _iron: StandardMaterial3D
var _batches := {}                ## Material -> SurfaceTool (static visuals merged: one draw call per material)


func _ready() -> void:
	_stone = Tex.material(Tex.bricks(), 1.0)
	_wood = Tex.material(Tex.planks(), 1.0)
	_dark_wood = Tex.material(Tex.planks(), 1.0, 0.55)
	_sack = Tex.material(Tex.burlap(), 0.5)
	_iron = Tex.material(Tex.rough(), 1.0, 0.8)
	_build_shell()
	_build_props()
	_build_lights()
	_flush_batches()
	apply_shadows(Settings.shadows)


## 0 = no shadows, 1 = window light only (cheap), 2 = window + lantern (costly cube map).
func apply_shadows(level: int) -> void:
	window_light.shadow_enabled = level >= 1
	lantern_light.shadow_enabled = level >= 2


func _batch(mesh: Mesh, xform: Transform3D, mat: Material) -> void:
	if not _batches.has(mat):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_batches[mat] = st
	(_batches[mat] as SurfaceTool).append_from(mesh, 0, xform)


func _flush_batches() -> void:
	for mat: Material in _batches:
		var st: SurfaceTool = _batches[mat]
		st.generate_tangents()
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = mat
		add_child(mi)
	_batches.clear()


# --- shell -------------------------------------------------------------------

func _build_shell() -> void:
	var t := 0.3
	_solid(Vector3(W + 2 * t, t, D + 2 * t), Vector3(0, -t / 2, 0), _wood)                 # floor
	_solid(Vector3(W + 2 * t, t, D + 2 * t), Vector3(0, H + t / 2, 0), _dark_wood)         # ceiling
	_solid(Vector3(W + 2 * t, H, t), Vector3(0, H / 2, -D / 2 - t / 2), _stone)            # back
	_solid(Vector3(W + 2 * t, H, t), Vector3(0, H / 2, D / 2 + t / 2), _stone)             # front
	_solid(Vector3(t, H, D), Vector3(-W / 2 - t / 2, H / 2, 0), _stone)                    # left
	_solid(Vector3(t, H, D), Vector3(W / 2 + t / 2, H / 2, 0), _stone)                     # right
	for z in [-1.8, -0.2, 1.4]:                                                            # ceiling beams
		_prop_box(Vector3(W, 0.22, 0.22), Vector3(0, H - 0.11, z), _dark_wood)

	# Door (front wall, behind the player's spawn).
	_prop_box(Vector3(1.1, 2.1, 0.12), Vector3(1.6, 1.05, D / 2 - 0.06), _dark_wood)
	_prop_box(Vector3(1.3, 0.12, 0.16), Vector3(1.6, 2.16, D / 2 - 0.08), _iron)
	var door := _interactable("Door", Vector3(1.0, 2.0, 0.3), Vector3(1.6, 1.0, D / 2 - 0.15))
	door.interacted.connect(func() -> void: pass)


# --- props -------------------------------------------------------------------

func _build_props() -> void:
	# Shelves on the back wall with jars and tins.
	for x in [-2.2, 0.0, 2.2]:
		_solid(Vector3(0.1, 2.2, 0.5), Vector3(x - 0.9, 1.1, -D / 2 + 0.3), _dark_wood)
		_solid(Vector3(0.1, 2.2, 0.5), Vector3(x + 0.9, 1.1, -D / 2 + 0.3), _dark_wood)
		for i in 3:
			var y := 0.45 + i * 0.7
			_solid(Vector3(1.9, 0.06, 0.5), Vector3(x, y, -D / 2 + 0.3), _wood)
			for j in 4:
				var h := 0.16 + Tex._hash(i * 7 + j, int(x * 10)) * 0.22
				_prop_box(Vector3(0.16, h, 0.16), Vector3(x - 0.65 + j * 0.4, y + 0.03 + h / 2, -D / 2 + 0.3), _iron)

	# Stacked sacks: the potato corner (right side).
	var sacks := [
		Vector3(2.3, 0.2, -0.4), Vector3(2.3, 0.2, 0.3), Vector3(2.3, 0.2, 1.0),
		Vector3(1.6, 0.2, 0.0), Vector3(1.6, 0.2, 0.7),
		Vector3(2.3, 0.58, -0.05), Vector3(2.3, 0.58, 0.65), Vector3(1.6, 0.58, 0.35),
		Vector3(2.3, 0.96, 0.3),
	]
	for i in sacks.size():
		_sack_at(sacks[i], i)

	# Barrels (left side) and crates.
	for p in [Vector3(-2.4, 0.45, 1.5), Vector3(-1.7, 0.45, 1.9), Vector3(-2.4, 0.45, 0.6)]:
		_barrel(p)
	_solid(Vector3(0.9, 0.7, 0.9), Vector3(-2.3, 0.35, -1.0), _dark_wood)
	_solid(Vector3(0.7, 0.5, 0.7), Vector3(-2.3, 0.95, -1.0), _wood)
	_solid(Vector3(0.8, 0.6, 0.8), Vector3(0.3, 0.3, -1.3), _wood)

	# A table with a tin cup in the middle.
	_solid(Vector3(1.2, 0.07, 0.7), Vector3(-0.3, 0.85, 0.4), _wood)
	for corner in [Vector2(-0.5, -0.28), Vector2(0.5, -0.28), Vector2(-0.5, 0.28), Vector2(0.5, 0.28)]:
		_prop_box(Vector3(0.07, 0.82, 0.07), Vector3(-0.3 + corner.x, 0.41, 0.4 + corner.y), _dark_wood)
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.05
	cyl.bottom_radius = 0.04
	cyl.height = 0.1
	cyl.radial_segments = 8
	_batch(cyl, Transform3D(Basis(), Vector3(-0.1, 0.94, 0.4)), _iron)


func _sack_at(pos: Vector3, i: int) -> void:
	var body := Interactable.new()
	body.prompt = "Sack"
	body.collision_layer = 1 | 2
	var cap := CapsuleMesh.new()
	cap.radius = 0.2
	cap.height = 0.78
	cap.radial_segments = 8
	cap.rings = 2
	var yaw := (Tex._hash(i, 3) - 0.5) * 16.0
	var basis := Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3.RIGHT, deg_to_rad(90))
	_batch(cap, Transform3D(basis, pos), _sack)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.4, 0.4, 0.78)
	shape.shape = box
	body.add_child(shape)
	body.position = pos
	body.rotation_degrees.y = yaw
	add_child(body)


func _barrel(pos: Vector3) -> void:
	var body := StaticBody3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.3
	cyl.bottom_radius = 0.3
	cyl.height = 0.9
	cyl.radial_segments = 10
	_batch(cyl, Transform3D(Basis(), pos), _wood)
	var bm := CylinderMesh.new()
	bm.top_radius = 0.315
	bm.bottom_radius = 0.315
	bm.height = 0.06
	bm.radial_segments = 10
	for y in [-0.28, 0.28]:
		_batch(bm, Transform3D(Basis(), pos + Vector3(0, y, 0)), _iron)
	var shape := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 0.3
	cs.height = 0.9
	shape.shape = cs
	body.add_child(shape)
	body.position = pos
	add_child(body)


# --- lights ------------------------------------------------------------------

func _build_lights() -> void:
	# Hanging lantern: the one warm key light.
	_prop_box(Vector3(0.02, 0.5, 0.02), Vector3(0.0, H - 0.25, -0.3), _iron)
	var lamp := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.09
	cyl.bottom_radius = 0.07
	cyl.height = 0.2
	cyl.radial_segments = 8
	lamp.mesh = cyl
	_lantern_mat = StandardMaterial3D.new()
	_lantern_mat.albedo_color = Color.WHITE
	_lantern_mat.emission_enabled = true
	_lantern_mat.emission = Color.WHITE
	_lantern_mat.emission_energy_multiplier = 3.0
	lamp.material_override = _lantern_mat
	lamp.position = Vector3(0.0, 2.1, -0.3)
	add_child(lamp)

	lantern_light = OmniLight3D.new()
	lantern_light.position = Vector3(0.0, 2.05, -0.3)
	lantern_light.omni_range = 7.5
	lantern_light.light_energy = 3.4
	lantern_light.omni_attenuation = 1.3
	add_child(lantern_light)

	# A high window on the left wall: a pale shaft of light across the sacks.
	var pane := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.9, 0.5)
	pane.mesh = q
	var pm := StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.albedo_color = Color.WHITE
	pane.material_override = pm
	pane.position = Vector3(-W / 2 + 0.02, 2.2, -0.8)
	pane.rotation_degrees.y = 90
	add_child(pane)

	window_light = SpotLight3D.new()
	window_light.position = Vector3(-W / 2 + 0.3, 2.3, -0.8)
	window_light.look_at_from_position(window_light.position, Vector3(1.8, 0.0, 0.2), Vector3.UP)
	window_light.spot_range = 9.0
	window_light.spot_angle = 28.0
	window_light.light_energy = 3.0
	add_child(window_light)

	# Lamp switch by the door: lets you see the room with the lantern off.
	var sw := _interactable("Lantern", Vector3(0.18, 0.28, 0.1), Vector3(0.5, 1.4, D / 2 - 0.06))
	sw.interacted.connect(toggle_lantern)
	_prop_box(Vector3(0.18, 0.28, 0.06), sw.position, _iron)


func toggle_lantern() -> void:
	_lantern_on = not _lantern_on
	lantern_light.visible = _lantern_on
	_lantern_mat.emission_energy_multiplier = 3.0 if _lantern_on else 0.0
	_lantern_mat.albedo_color = Color.WHITE if _lantern_on else Color(0.15, 0.15, 0.15)


func _process(delta: float) -> void:
	if not _lantern_on:
		return
	_flicker_t += delta
	var f := 1.0 + 0.05 * sin(_flicker_t * 9.0) + 0.04 * sin(_flicker_t * 23.0 + 1.0)
	lantern_light.light_energy = 3.4 * f


# --- helpers -----------------------------------------------------------------

func _solid(size: Vector3, pos: Vector3, mat: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var box := BoxMesh.new()
	box.size = size
	_batch(box, Transform3D(Basis(), pos), mat)
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)
	add_child(body)
	return body


func _prop_box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var box := BoxMesh.new()
	box.size = size
	_batch(box, Transform3D(Basis(), pos), mat)


func _interactable(label: String, size: Vector3, pos: Vector3) -> Interactable:
	var body := Interactable.new()
	body.prompt = label
	body.collision_layer = 2
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)
	body.position = pos
	add_child(body)
	return body
