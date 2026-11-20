class_name Island
extends Node3D
## The island, authored in Blender (tools/blender/build_island.py) from the outline of
## a real island: flat-shaded terrain with baked vertex colours, sea stacks, a foam mask.
## This script loads the model, gives it collision, and adds the sea, sky and jetty.
## Everything outdoors lives on visual layer 1 (sun and moon light layer 1 only).

const MODEL := "res://assets/models/island.glb"
const META := "res://assets/models/island_meta.json"
const SHORE_MASK := "res://assets/textures/shore_mask.png"
const SEA_Y := 0.0

var meta: Dictionary
var terrain_mesh: MeshInstance3D
var _sea_mat: ShaderMaterial
var _night_nodes: Array[Node3D] = []
var _moon: MeshInstance3D


func _ready() -> void:
	meta = JSON.parse_string(FileAccess.get_file_as_string(META))
	_build_terrain()
	_build_sea()
	_build_sky()
	_build_jetty()
	_build_boundary()


# --- landmarks (Godot coordinates) ----------------------------------------------

func lighthouse_position() -> Vector3:
	return _v(meta["lighthouse"])


## The unit vector from the quay out to sea (where boats come from).
func seaward() -> Vector3:
	var path: Array = meta["path"]
	var d := _v(path[0]) - _v(path[1])
	d.y = 0.0
	return d.normalized()


func jetty_end() -> Vector3:
	return _v(meta["landing"]) + seaward() * (QUAY_LENGTH - JETTY_OVERLAP + JETTY_LENGTH - 1.5) + Vector3(0, JETTY_Y, 0)


## Day 1 starts at the end of the jetty, facing the island: you have just been put ashore.
func spawn_point() -> Vector3:
	return jetty_end() + Vector3(0, 0.1, 0)


func spawn_yaw() -> float:
	var f := -seaward()
	return atan2(-f.x, -f.z)


func path_points() -> Array:
	return (meta["path"] as Array).map(func(p: Array) -> Vector3: return _v(p))


func _v(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])


# --- terrain -----------------------------------------------------------------

func _build_terrain() -> void:
	var scene := (load(MODEL) as PackedScene).instantiate()
	add_child(scene)
	var mat := Tex.material(Tex.rough(), 3.0, 2.6)
	mat.vertex_color_use_as_albedo = true
	for n in scene.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		mi.material_override = mat
		if mi.name.begins_with("Terrain"):
			terrain_mesh = mi
			var body := StaticBody3D.new()
			var shape := CollisionShape3D.new()
			shape.shape = mi.mesh.create_trimesh_shape()
			body.add_child(shape)
			add_child(body)


# --- sea and sky -------------------------------------------------------------

func _build_sea() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(900, 900)
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	_sea_mat = ShaderMaterial.new()
	_sea_mat.shader = preload("res://shaders/water.gdshader")
	_sea_mat.set_shader_parameter("shore_mask", load(SHORE_MASK))
	var b: Dictionary = meta["bounds"]
	_sea_mat.set_shader_parameter("bounds", Vector4(b["min_x"], b["min_z"], b["max_x"] - b["min_x"], b["max_z"] - b["min_z"]))
	mi.material_override = _sea_mat
	mi.position.y = SEA_Y
	add_child(mi)


func _build_sky() -> void:
	# Moon: a bright disc, unaffected by fog. Placed by set_night_sky().
	_moon = MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 7.0
	sph.height = 14.0
	sph.radial_segments = 12
	sph.rings = 6
	_moon.mesh = sph
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.albedo_color = Color.WHITE
	mm.disable_fog = true
	_moon.material_override = mm
	add_child(_moon)
	_night_nodes.append(_moon)

	var rng := RandomNumberGenerator.new()
	rng.seed = 1900
	var verts := PackedVector3Array()
	for i in 220:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.08, 1.0), rng.randf_range(-1, 1)).normalized()
		verts.append(dir * 250.0)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, arrays)
	var stars := MeshInstance3D.new()
	stars.mesh = am
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.albedo_color = Color(0.9, 0.9, 0.9)
	sm.use_point_size = true
	sm.point_size = 2.0
	sm.disable_fog = true
	stars.material_override = sm
	add_child(stars)
	_night_nodes.append(stars)


func set_night_sky(on: bool, light_dir: Vector3) -> void:
	for n in _night_nodes:
		n.visible = on
	_moon.position = light_dir * 240.0


func set_sea(base: float, glint: float) -> void:
	_sea_mat.set_shader_parameter("base", base)
	_sea_mat.set_shader_parameter("glint", glint)


# --- jetty -------------------------------------------------------------------

const QUAY_LENGTH := 14.0     ## how far the rock quay runs out to sea (see island_data.py)
const JETTY_LENGTH := 11.0
const JETTY_OVERLAP := 3.5    ## the deck starts this far back along the quay
const JETTY_Y := 1.42         ## deck top: just above the quay


func _build_jetty() -> void:
	var out := seaward()
	var start := _v(meta["landing"]) + out * (QUAY_LENGTH - JETTY_OVERLAP)
	var yaw := atan2(out.x, out.z)
	var basis := Basis(Vector3.UP, yaw)
	var mat := Tex.material(Tex.planks(), 1.0, 0.8)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var deck := BoxMesh.new()
	deck.size = Vector3(2.3, 0.16, JETTY_LENGTH)
	var center := start + out * (JETTY_LENGTH / 2.0)
	center.y = JETTY_Y - 0.08
	st.append_from(deck, 0, Transform3D(basis, center))
	var post := BoxMesh.new()
	post.size = Vector3(0.22, 3.4, 0.22)
	for k in [0.5, 3.8, 7.1, 10.4]:
		for sx in [-1.1, 1.1]:
			var p: Vector3 = start + out * k + basis * Vector3(sx, 0, 0)
			p.y = JETTY_Y - 1.7
			st.append_from(post, 0, Transform3D(basis, p))
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	add_child(mi)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = deck.size
	cs.shape = bs
	body.add_child(cs)
	body.transform = Transform3D(basis, center)
	add_child(body)


func _build_boundary() -> void:
	# Invisible walls at the edge of the modelled area.
	var b: Dictionary = meta["bounds"]
	var cx := (float(b["min_x"]) + float(b["max_x"])) / 2.0
	var cz := (float(b["min_z"]) + float(b["max_z"])) / 2.0
	var sx := float(b["max_x"]) - float(b["min_x"])
	var sz := float(b["max_z"]) - float(b["min_z"])
	for side in [[Vector3(b["max_x"], 0, cz), Vector3(2, 60, sz)], [Vector3(b["min_x"], 0, cz), Vector3(2, 60, sz)],
			[Vector3(cx, 0, b["max_z"]), Vector3(sx, 60, 2)], [Vector3(cx, 0, b["min_z"]), Vector3(sx, 60, 2)]]:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = side[1]
		cs.shape = bs
		body.add_child(cs)
		body.position = side[0] + Vector3(0, 10.0, 0)
		add_child(body)
