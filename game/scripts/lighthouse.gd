class_name Lighthouse
extends RoomKit
## The lighthouse: exterior from Blender (tools/blender/build_lighthouse.py), plus the
## interiors the game builds itself so indoor light stays separate from the sky:
##   entrance door -> hall -> stair door -> stairs down -> store door -> underground store.
## Local frame: origin at the tower's centre on the ground, +X east, +Z south.

const MODEL := "res://assets/models/lighthouse.glb"
const META := "res://assets/models/lighthouse_meta.json"
const T := 0.3                    ## thickness of the interior wall slabs (inside the modelled walls)
const FLOOR_Y := 0.1              ## hall floor, slightly above the ground so terrain never pokes through
const STAIR_TOP_Z := 4.6
const STAIR_BOTTOM_Z := 9.4
const STORE_FLOOR_Y := -3.4
const PARTITION_X := -3.2

var meta: Dictionary
var entrance_door: Door
var stair_door: Door
var store: StoreRoom
var _glass_mat: StandardMaterial3D
var _beam: Node3D
var _spot: SpotLight3D
var _gate_light: OmniLight3D
var _gate_mesh: MeshInstance3D
var _halo: MeshInstance3D
var _window_mat: StandardMaterial3D


func _ready() -> void:
	meta = JSON.parse_string(FileAccess.get_file_as_string(META))
	_init_materials()
	_build_exterior()
	_build_colliders()
	_build_hall()
	_build_stairs()
	_build_beam_and_lamps()
	_flush_batches()
	_build_store()


# --- exterior ----------------------------------------------------------------

func _build_exterior() -> void:
	_glass_mat = StandardMaterial3D.new()
	_glass_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glass_mat.albedo_color = Color(0.07, 0.07, 0.08)
	var scene := (load(MODEL) as PackedScene).instantiate()
	add_child(scene)
	_window_mat = StandardMaterial3D.new()
	_window_mat.albedo_color = Color(0.06, 0.06, 0.07)
	_window_mat.roughness = 0.2
	for n in scene.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		mi.mesh = Island.grey_mesh(mi.mesh)
		if n.name == "LH_glass":
			# The model has one glass mesh for the lantern room and the house windows. Only the lantern glows: the
			# windows stay dark, because nobody is in the house.
			var split := _split_by_height(mi.mesh, float(meta["tower"]["gallery_z"]) - 0.5)
			mi.mesh = split[0]
			mi.material_override = _window_mat
			var lantern := MeshInstance3D.new()
			lantern.mesh = split[1]
			lantern.material_override = _glass_mat
			mi.add_sibling(lantern)


## Splits a mesh into [triangles below y, triangles above y] (in the mesh's own space).
func _split_by_height(src: Mesh, y: float) -> Array:
	var lo := SurfaceTool.new()
	var hi := SurfaceTool.new()
	lo.begin(Mesh.PRIMITIVE_TRIANGLES)
	hi.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mdt := MeshDataTool.new()
	for si in src.get_surface_count():
		mdt.create_from_surface(src as ArrayMesh, si)
		for f in mdt.get_face_count():
			var c := Vector3.ZERO
			for k in 3:
				c += mdt.get_vertex(mdt.get_face_vertex(f, k))
			var st := hi if c.y / 3.0 > y else lo
			for k in 3:
				var vi := mdt.get_face_vertex(f, k)
				st.set_normal(mdt.get_vertex_normal(vi))
				st.add_vertex(mdt.get_vertex(vi))
	return [lo.commit(), hi.commit()]


func _collider(size: Vector3, pos: Vector3, shape_type := "box") -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	if shape_type == "cylinder":
		var c := CylinderShape3D.new()
		c.radius = size.x
		c.height = size.y
		cs.shape = c
	else:
		var b := BoxShape3D.new()
		b.size = size
		cs.shape = b
	body.add_child(cs)
	body.position = pos
	add_child(body)


func _build_colliders() -> void:
	var tw: Dictionary = meta["tower"]
	_collider(Vector3(2.95, 12.0, 0), Vector3(0, 6.0, 0), "cylinder")
	_collider(Vector3(3.25, 1.2, 0), Vector3(0, 0.6, 0), "cylinder")
	# Compound wall (Blender y is north, Godot z is south).
	var c: Dictionary = meta["compound"]
	var x0: float = c["x0"]
	var x1: float = c["x1"]
	var zn: float = -float(c["y1"])
	var zs: float = -float(c["y0"])
	var t: float = c["wall_t"]
	var h: float = c["wall_h"]
	var gw: float = c["gate_w"]
	_collider(Vector3(x1 - x0, h, t), Vector3(0, h / 2, zn + t / 2))
	_collider(Vector3(t, h, zs - zn), Vector3(x0 + t / 2, h / 2, (zn + zs) / 2))
	_collider(Vector3(t, h, zs - zn), Vector3(x1 - t / 2, h / 2, (zn + zs) / 2))
	var side := (x1 - x0 - gw) / 2.0
	_collider(Vector3(side, h, t), Vector3(x0 + side / 2, h / 2, zs - t / 2))
	_collider(Vector3(side, h, t), Vector3(x1 - side / 2, h / 2, zs - t / 2))
	_collider(Vector3(3.2, 2.4, 2.6), Vector3(7.2, 1.2, 9.6))                   # the oil store


# --- hall --------------------------------------------------------------------

func _hall_bounds() -> Dictionary:
	var b: Dictionary = meta["building"]
	var t: float = b["wall_t"]
	return {"xw": float(b["x0"]) + t - 0.03, "xe": float(b["x1"]) - t + 0.03,
			"zn": -float(b["y1"]) + t - 0.03, "zs": -float(b["y0"]) - t + 0.03,
			"h": 2.9, "door_x": float(b["door_x"]), "door_w": float(b["door_w"]), "door_h": float(b["door_h"])}


func _build_hall() -> void:
	var hb := _hall_bounds()
	var xw: float = hb["xw"]
	var xe: float = hb["xe"]
	var zn: float = hb["zn"]
	var zs: float = hb["zs"]
	var h: float = hb["h"]
	var dw: float = hb["door_w"]
	var dx: float = hb["door_x"]
	var wall_y0 := -0.8
	var wall_h := h - wall_y0
	var wall_cy := (h + wall_y0) / 2.0
	var width := xe - xw + 2 * T

	# Floor (hall only), ceiling, outer walls.
	var fx0 := PARTITION_X
	_solid(Vector3(xe + T - fx0, T, zs - zn + 2 * T), Vector3((fx0 + xe + T) / 2.0, FLOOR_Y - T / 2.0, (zn + zs) / 2.0), _wood)
	_solid(Vector3(width, T, zs - zn + 2 * T), Vector3(0, h + T / 2.0, (zn + zs) / 2.0), _dark_wood)
	_solid(Vector3(T, wall_h, zs - zn + 2 * T), Vector3(xe + T / 2.0, wall_cy, (zn + zs) / 2.0), _plaster)       # east
	_solid(Vector3(width, wall_h, T), Vector3(0, wall_cy, zn - T / 2.0), _plaster)                                # north
	var zc := zs + T / 2.0
	var left_w := (dx - dw / 2.0) - (xw - T)
	var right_w := (xe + T) - (dx + dw / 2.0)
	_solid(Vector3(left_w, wall_h, T), Vector3(xw - T + left_w / 2.0, wall_cy, zc), _plaster)                     # south, left of door
	_solid(Vector3(right_w, wall_h, T), Vector3(xe + T - right_w / 2.0, wall_cy, zc), _plaster)                   # south, right of door
	_solid(Vector3(dw, h - hb["door_h"] - FLOOR_Y, T), Vector3(dx, (h + hb["door_h"] + FLOOR_Y) / 2.0, zc), _plaster)   # lintel
	for z in [zn + 1.2, zn + 3.4]:                                                                                # ceiling beams
		_prop_box(Vector3(xe - xw, 0.2, 0.2), Vector3((xe + xw) / 2.0, h - 0.1, z), _dark_wood)

	# Entrance door: hinge on the left jamb, swings into the hall.
	entrance_door = make_door(dw, hb["door_h"] - FLOOR_Y + 0.1, Vector3(dx - dw / 2.0, FLOOR_Y, zs + T / 2.0))

	# Furniture: a table with three chairs (three keepers), a stove, shelves, a stopped clock.
	_solid(Vector3(1.7, 0.08, 0.95), Vector3(1.3, 0.85, 6.1), _wood)
	for cx in [-0.7, 0.7]:
		for cz in [-0.38, 0.38]:
			_prop_box(Vector3(0.08, 0.8, 0.08), Vector3(1.3 + cx, 0.45, 6.1 + cz), _dark_wood)
	for p in [Vector3(0.4, 0, 6.1), Vector3(2.2, 0, 6.1), Vector3(1.3, 0, 7.0)]:
		_solid(Vector3(0.45, 0.07, 0.45), p + Vector3(0, 0.48, 0), _dark_wood)
		_prop_box(Vector3(0.07, 0.5, 0.07), p + Vector3(-0.19, 0.2, -0.19), _dark_wood)
		_prop_box(Vector3(0.07, 0.5, 0.07), p + Vector3(0.19, 0.2, 0.19), _dark_wood)
	_solid(Vector3(0.9, 1.0, 0.7), Vector3(xe - 0.5, 0.6, 4.2), _iron)                                              # stove
	_prop_box(Vector3(0.2, 1.4, 0.2), Vector3(xe - 0.5, 1.7, 4.2), _iron)                                           # flue
	for y in [0.7, 1.3, 1.9]:                                                                                     # shelves, east wall
		_solid(Vector3(0.35, 0.05, 2.0), Vector3(xe - 0.2, y, 7.3), _wood)
	_prop_box(Vector3(0.1, 0.5, 0.5), Vector3(xe - 0.1, 2.15, zn + 1.0), _plaster)                                  # clock face
	_prop_box(Vector3(0.12, 0.54, 0.54), Vector3(xe - 0.09, 2.15, zn + 1.0), _iron)

	# Hall lantern.
	var lamp := _lamp_mesh(Vector3(0.6, 2.2, 6.1))
	lamp.layers = 2
	add_child(lamp)
	var light := OmniLight3D.new()
	light.position = Vector3(0.6, 2.15, 6.1)
	light.omni_range = 9.0
	light.light_energy = 3.0
	light.omni_attenuation = 1.2
	light.light_cull_mask = 2
	add_child(light)


func _lamp_mesh(pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.09
	cyl.bottom_radius = 0.07
	cyl.height = 0.2
	cyl.radial_segments = 8
	mi.mesh = cyl
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color.WHITE
	mi.material_override = m
	mi.position = pos
	return mi


# --- stairs down ---------------------------------------------------------------

func _build_stairs() -> void:
	var hb := _hall_bounds()
	var xw: float = hb["xw"]
	var zn: float = hb["zn"]
	var h: float = hb["h"]
	var x_c := (xw + (PARTITION_X - 0.1)) / 2.0                 # centre of the stairwell
	var width := (PARTITION_X - 0.1) - xw
	var bottom := STORE_FLOOR_Y
	var z_end := 9.5
	var y_lo := bottom - 0.3
	var side_h := h - y_lo
	var side_cy := (h + y_lo) / 2.0

	# Stairwell side walls (west and the partition) reach down to the store floor.
	_solid(Vector3(T, side_h, z_end - zn + T), Vector3(xw - T / 2.0, side_cy, (zn - T + z_end) / 2.0), _plaster)
	# Partition between hall and stairwell, with a doorway near the top of the stairs.
	var door_z0 := zn + 0.25
	var door_w := 0.9
	var door_h := 2.1
	var pz0 := zn - T
	var below_h := FLOOR_Y - y_lo
	_solid(Vector3(0.2, side_h, door_z0 - pz0), Vector3(PARTITION_X, side_cy, (pz0 + door_z0) / 2.0), _plaster)                  # north of the door
	_solid(Vector3(0.2, h - (FLOOR_Y + door_h), door_w), Vector3(PARTITION_X, (h + FLOOR_Y + door_h) / 2.0, door_z0 + door_w / 2.0), _plaster)   # lintel
	_solid(Vector3(0.2, below_h, door_w), Vector3(PARTITION_X, (FLOOR_Y + y_lo) / 2.0, door_z0 + door_w / 2.0), _plaster)         # solid under the sill
	_solid(Vector3(0.2, side_h, z_end - (door_z0 + door_w)), Vector3(PARTITION_X, side_cy, (door_z0 + door_w + z_end) / 2.0), _plaster)   # south of the door
	var holder := Node3D.new()                                   # door frame rotated: width runs along +Z, swings toward the hall (+X)
	holder.position = Vector3(PARTITION_X, 0, door_z0)
	holder.rotation.y = -PI / 2.0
	add_child(holder)
	stair_door = make_door(door_w, door_h, Vector3(0, FLOOR_Y, 0), holder)

	# Steps (visual) and a smooth ramp (collision) down to the store floor.
	var steps := 17
	var run := (STAIR_BOTTOM_Z - STAIR_TOP_Z) / steps
	var rise := (FLOOR_Y - bottom) / steps
	for i in steps:
		var top := FLOOR_Y - (i + 1) * rise
		_prop_box(Vector3(width, rise, run), Vector3(x_c, top - rise / 2.0, STAIR_TOP_Z + (i + 0.5) * run), _wood)
	_solid(Vector3(width, 0.3, 1.2), Vector3(x_c, FLOOR_Y - 0.15, (zn + STAIR_TOP_Z) / 2.0 + 0.1), _wood)                      # top landing
	var angle := atan((FLOOR_Y - bottom) / (STAIR_BOTTOM_Z - STAIR_TOP_Z))
	var length := sqrt(pow(STAIR_BOTTOM_Z - STAIR_TOP_Z, 2) + pow(FLOOR_Y - bottom, 2))
	var ramp_mid := Vector3(x_c, (FLOOR_Y + bottom) / 2.0 - rise / 2.0 - 0.1, (STAIR_TOP_Z + STAIR_BOTTOM_Z) / 2.0)
	_collider_oriented(Vector3(width, 0.2, length), ramp_mid, Basis(Vector3.RIGHT, angle))
	_solid(Vector3(width + 0.2, 0.3, 1.0), Vector3(x_c, bottom - 0.15, 9.3), _wood)                                              # bottom landing

	# Sloped ceiling parallel to the stairs keeps headroom sensible.
	var c_start := 4.2
	var c_len := sqrt(pow(z_end - c_start, 2) + pow((z_end - c_start) * tan(angle), 2))
	var c_mid := Vector3(x_c, h - (z_end - c_start) * tan(angle) / 2.0 + 0.1, (c_start + z_end) / 2.0)
	_solid(Vector3(width + 0.2, 0.2, c_len), c_mid, _dark_wood, Basis(Vector3.RIGHT, angle))

	# Stair lamps.
	for p in [Vector3(x_c, 0.9, 5.4), Vector3(x_c, -2.2, 8.6)]:
		var lamp := _lamp_mesh(p + Vector3(0.7, 0.4, 0))
		lamp.layers = 2
		add_child(lamp)
		var l := OmniLight3D.new()
		l.position = p
		l.omni_range = 4.8
		l.light_energy = 1.7
		l.light_cull_mask = 2
		add_child(l)


func _collider_oriented(size: Vector3, pos: Vector3, basis: Basis) -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = size
	cs.shape = b
	body.add_child(cs)
	body.transform = Transform3D(basis, pos)
	add_child(body)


# --- store, underground -------------------------------------------------------

func _build_store() -> void:
	store = StoreRoom.new()
	store.underground = true
	var x_c := ((_hall_bounds()["xw"] as float) + (PARTITION_X - 0.1)) / 2.0
	store.position = Vector3(x_c + 1.6, STORE_FLOOR_Y, 12.3)       # its door lines up with the stairwell
	store.rotation.y = PI                                           # front wall (with the door) faces north, toward the stairs
	add_child(store)


# --- lighting hooks ----------------------------------------------------------

func _build_beam_and_lamps() -> void:
	var tw: Dictionary = meta["tower"]
	_beam = Node3D.new()
	_beam.position = Vector3(0, float(tw["lantern_z"]), 0)
	_spot = SpotLight3D.new()
	_spot.spot_range = 120.0
	_spot.spot_angle = 12.0
	_spot.light_energy = 8.0
	_spot.light_cull_mask = 1
	_spot.rotation_degrees.x = -3.0
	_beam.add_child(_spot)
	# The visible shafts: two opposite beams, each two crossed quads with a soft additive falloff.
	var bm := _beam_material()
	for back in [0.0, PI]:
		for roll in [0.0, PI / 2.0]:
			var q := QuadMesh.new()
			q.size = Vector2(3.2, 70.0)
			var mi := MeshInstance3D.new()
			mi.mesh = q
			mi.material_override = bm
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var b := Basis(Vector3.UP, back) * Basis(Vector3.FORWARD, roll) * Basis(Vector3.RIGHT, -PI / 2.0)
			mi.transform = Transform3D(b, Basis(Vector3.UP, back) * Vector3(0, 0, -35.0))
			mi.extra_cull_margin = 80.0
			_beam.add_child(mi)
	add_child(_beam)
	# A soft halo round the lantern, as the lamp glows through rain and fog.
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 0.75), Color(1, 1, 1, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	var hm := StandardMaterial3D.new()
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	hm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	hm.albedo_texture = gt
	hm.disable_fog = true
	var hq := QuadMesh.new()
	hq.size = Vector2(7.0, 7.0)
	_halo = MeshInstance3D.new()
	_halo.mesh = hq
	_halo.material_override = hm
	_halo.position = Vector3(0, float(tw["lantern_z"]), 0)
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_halo)

	# A lamp beside the entrance door (outdoor layer).
	var pos := Vector3(1.25, 2.45, 9.55)
	_gate_mesh = _lamp_mesh(pos)
	_gate_mesh.layers = 1
	add_child(_gate_mesh)
	_gate_light = OmniLight3D.new()
	_gate_light.position = pos + Vector3(0, 0, 0.2)
	_gate_light.omni_range = 8.0
	_gate_light.light_energy = 2.4
	_gate_light.light_cull_mask = 1
	add_child(_gate_light)


func lantern_world() -> Vector3:
	return global_position + Vector3(0, float(meta["tower"]["lantern_z"]), 0)


## Additive, unshaded, with a falloff texture: bright at the lantern, fading along the shaft and toward its edges.
func _beam_material() -> StandardMaterial3D:
	var img := Image.create(16, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 16:
			var along := 1.0 - float(y) / 63.0                 # texture top (v = 0) is the far end
			var across := absf(float(x) / 15.0 - 0.5) * 2.0
			var a := (1.0 - smoothstep(0.0, 1.0, along)) * (1.0 - smoothstep(0.15, 1.0, across)) * 0.6
			img.set_pixel(x, y, Color(1, 1, 1, a))
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.disable_fog = true
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	return m


func set_beam(on: bool) -> void:
	_beam.visible = on
	_spot.visible = on
	_halo.visible = on
	_glass_mat.albedo_color = Color.WHITE if on else Color(0.07, 0.07, 0.08)


func set_porch(on: bool) -> void:
	_gate_light.visible = on
	_gate_mesh.visible = on


func apply_shadows(level: int) -> void:
	if store:
		store.apply_shadows(level)


func _process(delta: float) -> void:
	if _beam.visible:
		_beam.rotate_y(-0.45 * delta)
