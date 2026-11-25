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
var lamp_points: Array = []           ## where the pier lamps are (bulb positions)


func _ready() -> void:
	meta = JSON.parse_string(FileAccess.get_file_as_string(META))
	_build_terrain()
	_build_sea()
	_build_sky()
	_build_jetty()
	_build_boardwalk()
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
		mi.mesh = Island.grey_mesh(mi.mesh)                            # every source is grey: only the hand lantern is warm
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


# --- the boardwalk (the pier from the landing up to the lighthouse) -------------------------------------------
# A raised wooden walkway on posts that follows the path, with a two-strand rope railing on its seaward side and a
# small lamp on every fourth post. One merged mesh for the wood, one for the rope, one for the bulbs; the halos are
# one MultiMesh. The walking surface is one sloped collider per segment (a CharacterBody3D cannot climb risers).

const WALK_W := 1.5           ## deck width
const WALK_RAISE := 0.32      ## deck top above the path
const POST_STEP := 2.4        ## metres between railing posts
const LAMP_EVERY := 4         ## a lamp on every n-th post


func _build_boardwalk() -> void:
	var pts: Array = path_points()
	var wood := SurfaceTool.new()
	wood.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rope := SurfaceTool.new()
	rope.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bulbs := SurfaceTool.new()
	bulbs.begin(Mesh.PRIMITIVE_TRIANGLES)
	var out := seaward()
	var jetty_start := _v(meta["landing"]) + out * (QUAY_LENGTH - JETTY_OVERLAP)
	jetty_start.y = JETTY_Y
	var jetty_far := jetty_start + out * JETTY_LENGTH
	var deck_pts: Array = [jetty_start]                    # the walkway runs on from the jetty deck, with no step
	for p in pts:
		deck_pts.append((p as Vector3) + Vector3(0, WALK_RAISE, 0))
	# deck segments, each with its own sloped collider
	for i in deck_pts.size() - 1:
		var a: Vector3 = deck_pts[i]
		var b: Vector3 = deck_pts[i + 1]
		var d := b - a
		var basis := Basis.looking_at(d.normalized(), Vector3.UP)
		var box := BoxMesh.new()
		box.size = Vector3(WALK_W, 0.09, d.length() + 0.25)
		var center := (a + b) * 0.5 - basis.y * 0.045
		wood.append_from(box, 0, Transform3D(basis, center))
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(WALK_W, 0.2, d.length() + 0.25)
		cs.shape = bs
		body.add_child(cs)
		body.transform = Transform3D(basis, center - basis.y * 0.055)
		add_child(body)
		# cross-bearers under the deck every metre, and the deck reads as boards from below
		var n := int(d.length())
		for k in n:
			var c := a + d * ((float(k) + 0.5) / float(maxi(n, 1)))
			var bearer := BoxMesh.new()
			bearer.size = Vector3(WALK_W + 0.1, 0.1, 0.12)
			wood.append_from(bearer, 0, Transform3D(basis, c - basis.y * 0.14))
	_railing([jetty_far] + deck_pts, wood, rope, bulbs, 1.0)
	_commit_boardwalk(wood, rope, bulbs)


## Posts along one side of a polyline of deck points, rope between them, a lamp on every LAMP_EVERY-th post.
func _railing(deck_pts: Array, wood: SurfaceTool, rope: SurfaceTool, bulbs: SurfaceTool, side: float) -> void:
	var posts: Array = []
	var walked := 0.0
	var next_post := 0.3
	for i in deck_pts.size() - 1:
		var a: Vector3 = deck_pts[i]
		var b: Vector3 = deck_pts[i + 1]
		var seg := (b - a).length()
		var flat := Vector3(b.x - a.x, 0, b.z - a.z).normalized()
		var right := Vector3(-flat.z, 0, flat.x) * side
		while next_post <= walked + seg:
			var t := (next_post - walked) / seg
			posts.append(a.lerp(b, t) + right * (WALK_W * 0.5 - 0.05))
			next_post += POST_STEP
		walked += seg
	for k in posts.size():
		var p: Vector3 = posts[k]
		var lamp := k % LAMP_EVERY == 0
		var top := 1.55 if lamp else 1.05
		var post := BoxMesh.new()
		post.size = Vector3(0.12, top + 1.6, 0.12)
		wood.append_from(post, 0, Transform3D(Basis(), p + Vector3(0, (top - 1.6) * 0.5, 0)))
		if lamp:
			var arm := BoxMesh.new()
			arm.size = Vector3(0.06, 0.06, 0.26)
			wood.append_from(arm, 0, Transform3D(Basis(), p + Vector3(0, top - 0.04, 0)))
			var bulb := SphereMesh.new()
			bulb.radius = 0.07
			bulb.height = 0.14
			bulb.radial_segments = 8
			bulb.rings = 4
			var bp := p + Vector3(0, top - 0.16, 0)
			bulbs.append_from(bulb, 0, Transform3D(Basis(), bp))
			lamp_points.append(bp)
		if k > 0:
			var q: Vector3 = posts[k - 1]
			for hgt in [0.5, 0.92]:
				_rope_span(rope, q + Vector3(0, hgt, 0), p + Vector3(0, hgt, 0), 0.07)


## A sagging rope between two points: two straight pieces meeting a little below the middle.
func _rope_span(st: SurfaceTool, a: Vector3, b: Vector3, sag: float) -> void:
	var mid := (a + b) * 0.5 - Vector3(0, sag, 0)
	for pair in [[a, mid], [mid, b]]:
		var p0: Vector3 = pair[0]
		var p1: Vector3 = pair[1]
		var d := p1 - p0
		if d.length() < 0.01:
			continue
		var box := BoxMesh.new()
		box.size = Vector3(0.03, 0.03, d.length())
		st.append_from(box, 0, Transform3D(Basis.looking_at(d.normalized(), Vector3.UP if absf(d.normalized().y) < 0.95 else Vector3.RIGHT), (p0 + p1) * 0.5))


func _commit_boardwalk(wood: SurfaceTool, rope: SurfaceTool, bulbs: SurfaceTool) -> void:
	wood.generate_tangents()
	var wmi := MeshInstance3D.new()
	wmi.mesh = wood.commit()
	wmi.material_override = Tex.material(Tex.planks(), 1.0, 0.75)
	add_child(wmi)
	var rmi := MeshInstance3D.new()
	rmi.mesh = rope.commit()
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(0.12, 0.12, 0.12)
	rm.roughness = 1.0
	rmi.material_override = rm
	add_child(rmi)
	var bmi := MeshInstance3D.new()
	bmi.mesh = bulbs.commit()
	_bulb_mat = StandardMaterial3D.new()
	_bulb_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_bulb_mat.albedo_color = Color(0.55, 0.55, 0.55)
	bmi.material_override = _bulb_mat
	add_child(bmi)
	_bulb_nodes.append(bmi)
	# halos: one MultiMesh of camera-facing soft discs, shown at night
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
