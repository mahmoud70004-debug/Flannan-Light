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
var _batches := {}                ## [Material, layer] -> SurfaceTool (static visuals merged: one draw call each)
var door: Door
var porch_light: OmniLight3D


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


## Interior visuals live on layer 2 (lit by the room's lights only). The outside
## skin lives on layer 1 (lit by the moon). Layers keep moonlight out of the room.
func _batch(mesh: Mesh, xform: Transform3D, mat: Material, layer := 2) -> void:
	var key := [mat, layer]
	if not _batches.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_batches[key] = st
	(_batches[key] as SurfaceTool).append_from(mesh, 0, xform)


func _flush_batches() -> void:
	for key in _batches:
		var st: SurfaceTool = _batches[key]
		st.generate_tangents()
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = key[0]
		mi.layers = key[1]
		add_child(mi)
	_batches.clear()


# --- shell -------------------------------------------------------------------

const DOOR_X := 1.6        ## doorway centre on the front wall
const DOOR_W := 1.1
const DOOR_H := 2.1
const WALL_T := 0.3


func _build_shell() -> void:
	var t := WALL_T
	_solid(Vector3(W + 2 * t, t, D + 2 * t), Vector3(0, -t / 2, 0), _wood)                 # floor
	_wall(Vector3(W + 2 * t, t, D + 2 * t), Vector3(0, H + t / 2, 0), _dark_wood)          # ceiling
	_wall(Vector3(W + 2 * t, H, t), Vector3(0, H / 2, -D / 2 - t / 2), _stone)             # back
	_wall(Vector3(t, H, D), Vector3(-W / 2 - t / 2, H / 2, 0), _stone)                     # left
	_wall(Vector3(t, H, D), Vector3(W / 2 + t / 2, H / 2, 0), _stone)                      # right

	# Front wall with a doorway: left segment, right segment, lintel.
	var fz := D / 2 + t / 2
	var x0 := DOOR_X - DOOR_W / 2
	var x1 := DOOR_X + DOOR_W / 2
	var left_w := x0 - (-W / 2 - t)
	var right_w := (W / 2 + t) - x1
	_wall(Vector3(left_w, H, t), Vector3(-W / 2 - t + left_w / 2, H / 2, fz), _stone)
	_wall(Vector3(right_w, H, t), Vector3(x1 + right_w / 2, H / 2, fz), _stone)
	_wall(Vector3(DOOR_W, H - DOOR_H, t), Vector3(DOOR_X, DOOR_H + (H - DOOR_H) / 2, fz), _stone)

	for z in [-1.8, -0.2, 1.4]:                                                            # ceiling beams
		_prop_box(Vector3(W, 0.22, 0.22), Vector3(0, H - 0.11, z), _dark_wood)

	_build_door(Vector3(x0, 0.0, fz))
	_build_porch_lamp()


## A hanging lamp outside the door: the island's only warm light at the hut, and a
## focal point from far away. Outdoor layer (1), so it never lights the room.
func _build_porch_lamp() -> void:
	var pos := Vector3(DOOR_X + 0.95, 2.05, D / 2 + WALL_T + 0.25)
	var bracket := BoxMesh.new()
	bracket.size = Vector3(0.05, 0.05, 0.3)
	_batch(bracket, Transform3D(Basis(), pos + Vector3(0, 0.18, -0.12)), _iron, 1)
	var lamp := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.08
	cyl.bottom_radius = 0.06
	cyl.height = 0.18
	cyl.radial_segments = 8
	lamp.mesh = cyl
	var em := StandardMaterial3D.new()
	em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	em.albedo_color = Color.WHITE
	lamp.material_override = em
	lamp.position = pos
	lamp.layers = 1
	add_child(lamp)
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 0, 0.1)
	light.omni_range = 7.0
	light.light_energy = 2.4
	light.omni_attenuation = 1.2
	light.light_cull_mask = 1
	add_child(light)
	porch_light = light


## A wall slab: interior face on layer 2, plus a slightly larger skin on layer 1
## so it looks right (and catches moonlight) from outside.
func _wall(size: Vector3, pos: Vector3, mat: Material) -> void:
	_solid(size, pos, mat)
	var skin := BoxMesh.new()
	skin.size = size + Vector3.ONE * 0.08
	_batch(skin, Transform3D(Basis(), pos), mat, 1)


func _build_door(hinge: Vector3) -> void:
	door = Door.new()
	door.collision_layer = 1 | 2
	door.position = hinge + Vector3(0, DOOR_H / 2, 0)
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(DOOR_W - 0.04, DOOR_H - 0.04, 0.12)
	shape.shape = bs
	shape.position = Vector3(DOOR_W / 2, 0, 0)
	door.add_child(shape)

	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(DOOR_W - 0.04, DOOR_H - 0.04, 0.12)
	mi.mesh = box
	mi.material_override = _dark_wood
	mi.layers = 1 | 2                      # lit by the moon outside and the lantern inside
	mi.position = Vector3(DOOR_W / 2, 0, 0)
	door.add_child(mi)
	for y in [-0.7, 0.7]:                  # iron straps
		var strap := MeshInstance3D.new()
		var sb := BoxMesh.new()
		sb.size = Vector3(DOOR_W - 0.1, 0.1, 0.15)
		strap.mesh = sb
		strap.material_override = _iron
		strap.layers = 1 | 2
		strap.position = Vector3(DOOR_W / 2, y, 0)
		door.add_child(strap)
	var handle := MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(0.05, 0.18, 0.2)
	handle.mesh = hb
	handle.material_override = _iron
	handle.layers = 1 | 2
	handle.position = Vector3(DOOR_W - 0.15, 0.0, 0)
	door.add_child(handle)
	add_child(door)

	var catch_body := DoorCatch.new()
	catch_body.door = door
	catch_body.collision_layer = 2          # interaction ray only; the player walks straight through
	catch_body.collision_mask = 0
	var cshape := CollisionShape3D.new()
	var cbox := BoxShape3D.new()
	cbox.size = Vector3(DOOR_W - 0.1, DOOR_H - 0.1, 0.4)
	cshape.shape = cbox
	catch_body.add_child(cshape)
	catch_body.position = hinge + Vector3(DOOR_W / 2, DOOR_H / 2, 0)
	add_child(catch_body)


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
	lamp.layers = 2
	add_child(lamp)

	lantern_light = OmniLight3D.new()
	lantern_light.position = Vector3(0.0, 2.05, -0.3)
	lantern_light.omni_range = 7.5
	lantern_light.light_energy = 3.4
	lantern_light.omni_attenuation = 1.3
	lantern_light.light_cull_mask = 2
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
	pane.layers = 2
	add_child(pane)

	window_light = SpotLight3D.new()
	var wpos := Vector3(-W / 2 + 0.3, 2.3, -0.8)
	window_light.transform = Transform3D(Basis.looking_at(Vector3(1.8, 0.0, 0.2) - wpos, Vector3.UP), wpos)
	window_light.light_cull_mask = 2
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
