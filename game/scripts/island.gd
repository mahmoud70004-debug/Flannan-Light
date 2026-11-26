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
var _bulb_nodes: Array = []
var _bulb_mat: StandardMaterial3D
var _halos: MultiMeshInstance3D
var lamp_points: Array = []           ## where the stair lamps are (bulb positions)
var _terrain_shape: CollisionShape3D


func _ready() -> void:
	meta = JSON.parse_string(FileAccess.get_file_as_string(META))
	_build_terrain()
	_build_sea()
	_build_sky()
	_build_walk()
	_build_boulders()
	_build_boundary()


# --- landmarks (Godot coordinates) ----------------------------------------------

func lighthouse_position() -> Vector3:
	return _v(meta["lighthouse"])


## The unit vector from the island out to sea at the landing (where boats come from). The tower's door faces it.
func seaward() -> Vector3:
	return _v(meta["seaward"]).normalized()


func tower_yaw() -> float:
	var s := seaward()
	return atan2(s.x, s.z)


func door_point() -> Vector3:
	return _v(meta["door"])


## The walk from the end of the dock up the stair to the cliff-top: dock end, stair foot, the flights and landings.
## Heights are the walking surface.
func walk_points() -> Array:
	var pts: Array = [_v(meta["dock"][1]) + Vector3(0, WALK_LIFT, 0)]
	for p in meta["stair"]:
		pts.append(_v(p) + Vector3(0, WALK_LIFT, 0))
	return pts


func path_points() -> Array:
	return walk_points()


## Day 1 starts at the end of the dock, facing the island: you have just been put ashore.
func spawn_point() -> Vector3:
	return walk_points()[0] - seaward() * 1.2 + Vector3(0, 0.1, 0)


func spawn_yaw() -> float:
	var f := -seaward()
	return atan2(-f.x, -f.z)


func _v(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])


# --- terrain -----------------------------------------------------------------

func _build_terrain() -> void:
	var scene := (load(MODEL) as PackedScene).instantiate()
	add_child(scene)
	var mat := Tex.material(Tex.rock(), 3.0, 1.35, 2.5)
	mat.vertex_color_use_as_albedo = true
	for n in scene.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		mi.material_override = mat
		mi.mesh = Island.grey_mesh(mi.mesh)                            # every source is grey: only the hand lantern is warm
		if mi.name.begins_with("Terrain"):
			terrain_mesh = mi
			var body := StaticBody3D.new()
			var shape := CollisionShape3D.new()
			shape.shape = mi.mesh.create_trimesh_shape()
			body.add_child(shape)
			_terrain_shape = shape
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


var _sky_dome: MeshInstance3D
var _sky_mat: ShaderMaterial


## A dome of storm clouds that follows the camera (see shaders/sky_clouds.gdshader).
func _build_sky() -> void:
	var sph := SphereMesh.new()
	sph.radius = 240.0
	sph.height = 480.0
	sph.radial_segments = 24
	sph.rings = 12
	_sky_dome = MeshInstance3D.new()
	_sky_dome.mesh = sph
	_sky_mat = ShaderMaterial.new()
	_sky_mat.shader = preload("res://shaders/sky_clouds.gdshader")
	_sky_dome.material_override = _sky_mat
	_sky_dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sky_dome.extra_cull_margin = 16384.0
	add_child(_sky_dome)


func set_sky(p: Dictionary) -> void:
	_sky_mat.set_shader_parameter("top_color", p["sky_top"])
	_sky_mat.set_shader_parameter("horizon_color", p["sky_horizon"])
	_sky_mat.set_shader_parameter("cloud_bright", p.get("cloud_bright", 0.7))
	_sky_mat.set_shader_parameter("cloud_dark", p.get("cloud_dark", 0.3))
	_sky_mat.set_shader_parameter("cloud_cover", p.get("cloud_cover", 0.65))
	_sky_mat.set_shader_parameter("glow", p.get("sky_glow", 0.0))
	for b in _bulb_nodes:
		(b as GeometryInstance3D).visible = true
	if _bulb_mat:
		_bulb_mat.albedo_color = Color(1, 1, 1) if p.get("night", false) else Color(0.55, 0.55, 0.55)
	if _halos:
		_halos.visible = p.get("night", false)


## Called every frame: the dome stays centred on the camera; the clouds glow toward the lantern.
func update_sky(cam_pos: Vector3, lantern_pos: Vector3) -> void:
	_sky_dome.global_position = cam_pos
	_sky_mat.set_shader_parameter("glow_dir", (lantern_pos - cam_pos).normalized())


## The same mesh with its vertex colours turned to grey (the Blender models carry tinted colours).
static func grey_mesh(src: Mesh) -> Mesh:
	if src == null or not (src is ArrayMesh):
		return src
	var out := ArrayMesh.new()
	for i in src.get_surface_count():
		var arr := src.surface_get_arrays(i)
		var cols = arr[Mesh.ARRAY_COLOR]
		if cols is PackedColorArray:
			var g := PackedColorArray()
			g.resize(cols.size())
			for k in cols.size():
				var c: Color = cols[k]
				var l := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
				g[k] = Color(l, l, l, c.a)
			arr[Mesh.ARRAY_COLOR] = g
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		out.surface_set_material(i, src.surface_get_material(i))
	return out


func set_sea(base: float, glint: float) -> void:
	_sea_mat.set_shader_parameter("base", base)
	_sea_mat.set_shader_parameter("glint", glint)


# --- the landing: a dock, then a wooden stair in three flights up the cliff ------------------------------------
# One polyline runs from the end of the dock to the cliff-top. The walking surface and the rails on both sides are
# one continuous collision mesh built from the same mitred outline: no step, no gap, no way off. The rope and posts
# are only for the eye; the rail walls behind them are what stop you.

const WALK_W := 1.6           ## width of the dock and the stair
const WALK_LIFT := 0.05       ## the deck sits this much above the stair line in the terrain data
const RAIL_H := 1.25          ## height of the rail walls
const POST_STEP := 1.9        ## metres between rail posts
const TREAD_RISE := 0.19

var walk_left: Array = []
var walk_right: Array = []


## Left and right edges of a polyline of width w, mitred at the corners (left = your left walking forward).
static func edges(pts: Array, w: float) -> Array:
	var left: Array = []
	var right: Array = []
	var n := pts.size()
	for i in n:
		var p: Vector3 = pts[i]
		var dirs: Array = []
		if i > 0:
			dirs.append(_flat(p - pts[i - 1]))
		if i < n - 1:
			dirs.append(_flat(pts[i + 1] - p))
		var sum := Vector3.ZERO
		for d in dirs:
			sum += Vector3(d.z, 0, -d.x)
		var m := sum.normalized()
		var lft := Vector3(dirs[0].z, 0, -dirs[0].x)
		var k := (w / 2.0) / maxf(m.dot(lft), 0.4)
		left.append(p + m * k)
		right.append(p - m * k)
	return [left, right]


static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0, v.z).normalized()


static func _hull(pts: Array) -> Array:
	var p := pts.duplicate()
	p.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.x < b.x or (a.x == b.x and a.z < b.z))
	var cross := func(o: Vector3, a: Vector3, b: Vector3) -> float: return (a.x - o.x) * (b.z - o.z) - (a.z - o.z) * (b.x - o.x)
	var lower: Array = []
	for q in p:
		while lower.size() >= 2 and cross.call(lower[-2], lower[-1], q) <= 0.0:
			lower.pop_back()
		lower.append(q)
	var upper: Array = []
	for i in range(p.size() - 1, -1, -1):
		var q: Vector3 = p[i]
		while upper.size() >= 2 and cross.call(upper[-2], upper[-1], q) <= 0.0:
			upper.pop_back()
		upper.append(q)
	lower.pop_back()
	upper.pop_back()
	return lower + upper


func _build_walk() -> void:
	var pts := walk_points()
	var e := edges(pts, WALK_W)
	walk_left = e[0]
	walk_right = e[1]
	var n := pts.size()

	# Collision: the walking surface, a rail wall on each side, and one across the end of the dock. The top of the
	# stair is left open onto the cliff-top.
	var col := MeshBuilder.new()
	for i in n - 1:
		col.quad(walk_left[i], walk_right[i], walk_right[i + 1], walk_left[i + 1], Vector3.UP)
	var down := Vector3(0, -0.3, 0)
	col.ribbon(walk_left.map(func(p: Vector3) -> Vector3: return p + down), RAIL_H + 0.3)
	col.ribbon(walk_right.map(func(p: Vector3) -> Vector3: return p + down), RAIL_H + 0.3)
	col.ribbon([walk_left[0] + down, walk_right[0] + down], RAIL_H + 0.3)
	add_child(MeshBuilder.body_from(col.faces))

	# Visuals: plank decks on the flat parts, open treads on stringers up the flights, a pad at every turn.
	var wood := MeshBuilder.new(false)
	var dark := MeshBuilder.new(false)
	for i in n - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var d := _flat(b - a)
		var yaw := Basis.looking_at(d, Vector3.UP)
		var run := Vector2(b.x - a.x, b.z - a.z).length()
		var rise := b.y - a.y
		var side := Vector3(-d.z, 0, d.x)
		if absf(rise) < 0.05:
			var planks := maxi(1, int(run / 0.24))
			for k in planks:
				var c := a.lerp(b, (k + 0.5) / planks)
				wood.box(Transform3D(yaw, c - Vector3(0, 0.045, 0)), Vector3(WALK_W, 0.09, run / planks - 0.03))
			for s in [-0.62, 0.62]:
				dark.box(Transform3D(yaw, (a + b) / 2.0 + side * s - Vector3(0, 0.18, 0)), Vector3(0.14, 0.18, run))
		else:
			var steps := maxi(1, roundi(absf(rise) / TREAD_RISE))
			for k in steps:
				var s := (k + 0.5) / steps
				var c := a.lerp(b, s)
				var top := c.y + absf(rise) * 0.25 / steps
				wood.box(Transform3D(yaw, Vector3(c.x, top - 0.03, c.z)), Vector3(WALK_W - 0.12, 0.06, run / steps + 0.03))
			var slope := Basis.looking_at((b - a).normalized(), Vector3.UP)
			for s in [-1.0, 1.0]:
				dark.box(Transform3D(slope, (a + b) / 2.0 + side * s * (WALK_W / 2.0 - 0.05) - Vector3(0, 0.12, 0)),
						Vector3(0.08, 0.3, (b - a).length() + 0.2))
	for i in range(1, n - 1):
		var p: Vector3 = pts[i]
		var din := _flat(p - pts[i - 1])
		var dout := _flat(pts[i + 1] - p)
		var h := WALK_W / 2.0
		var ring: Array = [walk_left[i], walk_right[i]]
		for d in [din, dout]:
			var l := Vector3(d.z, 0, -d.x)
			ring.append(p + l * h)
			ring.append(p - l * h)
		wood.prism(_hull(ring), p.y - 0.1, p.y)
	# Piles under the dock, into the sea floor.
	var dock_a: Vector3 = pts[0]
	var dock_b: Vector3 = pts[1]
	var dd := _flat(dock_b - dock_a)
	var dside := Vector3(-dd.z, 0, dd.x)
	var dlen := Vector2(dock_b.x - dock_a.x, dock_b.z - dock_a.z).length()
	var k2 := 0.3
	while k2 <= dlen:
		for s in [-0.7, 0.7]:
			var pp: Vector3 = dock_a + dd * k2 + dside * s
			dark.box(Transform3D(Basis(), Vector3(pp.x, (pp.y - 4.0) / 2.0 - 0.1, pp.z)), Vector3(0.24, pp.y + 4.0, 0.24))
		k2 += 2.4
	# Posts along both rails, a rope in two strands between them, and a lamp at every turn.
	var rope := MeshBuilder.new(false)
	var bulbs := MeshBuilder.new(false)
	for side_pts in [walk_left, walk_right]:
		var posts: Array = []
		var lamps: Array = []
		for i in side_pts.size() - 1:
			var a: Vector3 = side_pts[i]
			var b: Vector3 = side_pts[i + 1]
			var seg := (b - a).length()
			var cnt := maxi(1, ceili(seg / POST_STEP))
			for k in cnt:
				posts.append(a.lerp(b, float(k) / cnt))
				lamps.append(k == 0 and side_pts == walk_left)
		posts.append(side_pts[-1])
		lamps.append(side_pts == walk_left)
		for k in posts.size():
			var p: Vector3 = posts[k]
			var top := 1.6 if lamps[k] else 1.12
			dark.box(Transform3D(Basis(), p + Vector3(0, (top - 1.8) / 2.0, 0)), Vector3(0.11, top + 1.8, 0.11))
			if lamps[k]:
				dark.box(Transform3D(Basis(), p + Vector3(0, top - 0.04, 0)), Vector3(0.24, 0.05, 0.05))
				var bp := p + Vector3(0, top - 0.17, 0)
				bulbs.box(Transform3D(Basis(), bp), Vector3(0.12, 0.17, 0.12))
				lamp_points.append(bp)
			if k > 0:
				var q: Vector3 = posts[k - 1]
				for hgt in [0.55, 1.02]:
					_rope_span(rope, q + Vector3(0, hgt, 0), p + Vector3(0, hgt, 0), 0.07)
	var wmi := wood.instance(Tex.material(Tex.planks(), 1.0, 0.8, 1.8))
	add_child(wmi)
	add_child(dark.instance(Tex.material(Tex.planks(), 1.0, 0.45, 1.8)))
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(0.13, 0.13, 0.13)
	rm.roughness = 1.0
	add_child(rope.instance(rm))
	_bulb_mat = StandardMaterial3D.new()
	_bulb_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_bulb_mat.albedo_color = Color(0.55, 0.55, 0.55)
	var bmi := bulbs.instance(_bulb_mat)
	add_child(bmi)
	_bulb_nodes.append(bmi)
	_build_halos()


## A sagging rope between two points: two straight pieces meeting a little below the middle.
func _rope_span(b: MeshBuilder, p0: Vector3, p1: Vector3, sag: float) -> void:
	var mid := (p0 + p1) * 0.5 - Vector3(0, sag, 0)
	for pair in [[p0, mid], [mid, p1]]:
		var a: Vector3 = pair[0]
		var c: Vector3 = pair[1]
		var d := c - a
		if d.length() < 0.01:
			continue
		var up := Vector3.UP if absf(d.normalized().y) < 0.95 else Vector3.RIGHT
		b.box(Transform3D(Basis.looking_at(d.normalized(), up), (a + c) * 0.5), Vector3(0.035, 0.035, d.length()))


## Soft camera-facing discs round the lamps, shown at night (one MultiMesh).
func _build_halos() -> void:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 64
	gt.height = 64
	var hm := StandardMaterial3D.new()
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	hm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	hm.albedo_texture = gt
	hm.disable_fog = true
	var q := QuadMesh.new()
	q.size = Vector2(1.3, 1.3)
	q.material = hm
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = q
	mm.instance_count = lamp_points.size()
	for i in lamp_points.size():
		mm.set_instance_transform(i, Transform3D(Basis(), lamp_points[i]))
	_halos = MultiMeshInstance3D.new()
	_halos.multimesh = mm
	_halos.visible = false
	add_child(_halos)


# --- boulders: big rough rocks round the cove and beside the stair ------------------------------------------------

func _build_boulders() -> void:
	var b := MeshBuilder.new(false)
	for item in meta.get("boulders", []):
		var pos := Vector3(item[0], item[1], item[2])
		var r: float = item[3]
		var rng := RandomNumberGenerator.new()
		rng.seed = int(item[4])
		var sph := SphereMesh.new()
		sph.radius = 1.0
		sph.height = 2.0
		sph.radial_segments = 9
		sph.rings = 5
		var arr := sph.get_mesh_arrays()
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		var sx := r * rng.randf_range(0.65, 0.95)
		var sy := r * rng.randf_range(0.45, 0.75)
		var sz := r * rng.randf_range(0.65, 0.95)
		var rot := Basis(Vector3.UP, rng.randf() * TAU)
		var centre := pos + Vector3(0, sy * 0.2, 0)
		var moved := PackedVector3Array()
		for v in verts:
			var key := Vector3i(roundi(v.x * 40.0), roundi(v.y * 40.0), roundi(v.z * 40.0))
			var k := 0.78 + float(absi(hash([key, int(item[4])])) % 1000) / 1000.0 * 0.42
			moved.append(centre + rot * (Vector3(v.x * sx, maxf(v.y, -0.4) * sy, v.z * sz) * k))
		for t in range(0, idx.size(), 3):
			var p0 := moved[idx[t]]
			var p1 := moved[idx[t + 1]]
			var p2 := moved[idx[t + 2]]
			var nrm := (p1 - p0).cross(p2 - p0)
			if nrm.length() < 1e-5:
				continue
			nrm = nrm.normalized()
			if nrm.dot((p0 + p1 + p2) / 3.0 - centre) < 0.0:
				nrm = -nrm
			b.tri(p0, p1, p2, nrm, nrm, nrm)
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var shape := ConvexPolygonShape3D.new()
		shape.points = moved
		cs.shape = shape
		body.add_child(cs)
		add_child(body)
	if not b.is_empty():
		add_child(b.instance(Tex.material(Tex.rock(), 2.0, 0.6, 3.0)))


## Removes the terrain's triangles over a rectangle given in another node's frame (the tower cuts a hole for the
## oil-store stair; its shed covers the edges).
func cut_terrain(xf: Transform3D, rect: Rect2) -> void:
	var mesh := terrain_mesh.mesh as ArrayMesh
	var arr := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if idx.is_empty():
		idx = PackedInt32Array(range(verts.size()))
	var to_local := xf.affine_inverse() * terrain_mesh.global_transform
	var keep := PackedInt32Array()
	for t in range(0, idx.size(), 3):
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for k in 3:
			var p := to_local * verts[idx[t + k]]
			lo = lo.min(Vector2(p.x, p.z))
			hi = hi.max(Vector2(p.x, p.z))
		if Rect2(lo, hi - lo).intersects(rect):
			continue
		keep.append(idx[t])
		keep.append(idx[t + 1])
		keep.append(idx[t + 2])
	arr[Mesh.ARRAY_INDEX] = keep
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	terrain_mesh.mesh = out
	_terrain_shape.shape = out.create_trimesh_shape()


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
