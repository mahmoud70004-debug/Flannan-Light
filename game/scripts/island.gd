class_name Island
extends Node3D
## The island: terrain from a height function (flat-shaded, low poly), sea,
## sky, rocks, jetty and a placeholder tower with a sweeping beam.
## Everything outdoors lives on visual layer 1 (the moon lights layer 1 only).

const CELL := 2.0
const HALF := 56.0            ## terrain covers -HALF..HALF on x and z
const SEMI_A := 42.0          ## island half-length (x)
const SEMI_B := 36.0          ## island half-width (z)
const PLATEAU := 12.0         ## height of the top above the sea
const HUT_CENTER := Vector2(-12.0, -4.0)
const HUT_HALF := Vector2(3.6, 3.1)
const TOWER_CENTER := Vector2(10.0, -8.0)
const TOWER_HALF := Vector2(4.0, 4.0)
const RAMP_X := 0.0
const JETTY_START := 31.0
const SEA_Y := 0.0

var _coast := FastNoiseLite.new()
var _mound := FastNoiseLite.new()
var _rough := FastNoiseLite.new()
var _beam: Node3D
var _rock_mat: StandardMaterial3D
var _wood_mat: StandardMaterial3D


func _ready() -> void:
	_coast.seed = 1900
	_coast.frequency = 0.03
	_mound.seed = 12
	_mound.frequency = 0.08
	_rough.seed = 25
	_rough.frequency = 0.22
	_rock_mat = Tex.material(Tex.rough(), 2.0, 1.4)
	_wood_mat = Tex.material(Tex.planks(), 1.0, 0.8)
	_build_terrain()
	_build_sea()
	_build_sky()
	_build_rocks()
	_build_jetty()
	_build_tower()
	_build_boundary()


## Height of the ground (metres above the sea) at world x, z.
func height_at(x: float, z: float) -> float:
	var r := Vector2(x / SEMI_A, z / SEMI_B).length() + _coast.get_noise_2d(x, z) * 0.16
	var t := smoothstep(0.50, 0.90, r)
	var h := lerpf(PLATEAU, -7.0, t)
	h += _mound.get_noise_2d(x, z) * 1.3 * (1.0 - t)
	h += _rough.get_noise_2d(x, z) * 2.4 * t * (1.0 - t) * 4.0

	# Landing ramp cut through the south cliffs, down to the jetty.
	var ramp := lerpf(PLATEAU, 0.35, smoothstep(8.0, 30.0, z))
	if z > 30.0:
		ramp -= (z - 30.0) * 0.16
	h = lerpf(h, ramp, 1.0 - smoothstep(2.6, 6.5, absf(x - RAMP_X)))

	# Level pads for the hut and the tower.
	h = lerpf(h, PLATEAU - 0.08, _pad(x, z, HUT_CENTER, HUT_HALF))
	h = lerpf(h, PLATEAU, _pad(x, z, TOWER_CENTER, TOWER_HALF))
	return h


func _pad(x: float, z: float, c: Vector2, e: Vector2) -> float:
	var d := Vector2(maxf(absf(x - c.x) - e.x, 0.0), maxf(absf(z - c.y) - e.y, 0.0)).length()
	return 1.0 - smoothstep(0.0, 5.0, d)


func hut_position() -> Vector3:
	return Vector3(HUT_CENTER.x, PLATEAU, HUT_CENTER.y)


func spawn_point() -> Vector3:
	return Vector3(RAMP_X, height_at(RAMP_X, 29.0) + 0.1, 29.0)


# --- terrain -----------------------------------------------------------------

func _build_terrain() -> void:
	var n := int(2.0 * HALF / CELL) + 1
	var hs := PackedFloat32Array()
	hs.resize(n * n)
	for iz in n:
		for ix in n:
			hs[iz * n + ix] = height_at(-HALF + ix * CELL, -HALF + iz * CELL)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in n - 1:
		for ix in n - 1:
			var x0 := -HALF + ix * CELL
			var z0 := -HALF + iz * CELL
			var a := Vector3(x0, hs[iz * n + ix], z0)
			var b := Vector3(x0 + CELL, hs[iz * n + ix + 1], z0)
			var c := Vector3(x0, hs[(iz + 1) * n + ix], z0 + CELL)
			var d := Vector3(x0 + CELL, hs[(iz + 1) * n + ix + 1], z0 + CELL)
			# Split the quad along its shorter diagonal so ridges stay sharp.
			if absf(a.y - d.y) < absf(b.y - c.y):
				_tri(st, a, b, d, ix, iz)
				_tri(st, a, d, c, ix, iz)
			else:
				_tri(st, a, b, c, ix, iz)
				_tri(st, b, d, c, ix, iz)
	var mesh := st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	# Texture (~0.34) x vertex colour (0.2-0.7): the tint lifts the product to a readable range.
	var m := Tex.material(Tex.rough(), 3.0, 2.7)
	m.vertex_color_use_as_albedo = true
	mi.material_override = m
	add_child(mi)

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = mesh.create_trimesh_shape()
	body.add_child(shape)
	add_child(body)


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ix: int, iz: int) -> void:
	var nrm := (c - a).cross(b - a).normalized()
	var slope := 1.0 - nrm.y
	var avg := (a.y + b.y + c.y) / 3.0
	var v := lerpf(0.36, 0.70, clampf(slope * 2.4, 0.0, 1.0))
	v += (Tex._hash(ix, iz) - 0.5) * 0.05
	if avg < 1.2:
		v = lerpf(v, 0.16, clampf((1.2 - avg) / 1.2, 0.0, 1.0))   # wet rock at the waterline
	var col := Color(v, v, v)
	for p in [a, b, c]:
		st.set_normal(nrm)
		st.set_color(col)
		st.add_vertex(p)


# --- sea and sky -------------------------------------------------------------

func _build_sea() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(700, 700)
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	var sm := ShaderMaterial.new()
	sm.shader = preload("res://shaders/water.gdshader")
	mi.material_override = sm
	mi.position.y = SEA_Y
	add_child(mi)


func _build_sky() -> void:
	# Moon: a bright disc, unaffected by fog. Direction matches the directional light.
	var moon := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 7.0
	sph.height = 14.0
	sph.radial_segments = 12
	sph.rings = 6
	moon.mesh = sph
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.albedo_color = Color.WHITE
	mm.disable_fog = true
	moon.material_override = mm
	moon.position = moon_direction() * 240.0
	add_child(moon)

	# Stars: one points mesh, one draw call.
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


func moon_direction() -> Vector3:
	return Vector3(-0.5, 0.5, 0.7).normalized()   # behind the player at the landing: faces seen on approach are lit


# --- props -------------------------------------------------------------------

func _build_rocks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var placed := 0
	var tries := 0
	while placed < 34 and tries < 600:
		tries += 1
		var x := rng.randf_range(-HALF + 6.0, HALF - 6.0)
		var z := rng.randf_range(-HALF + 6.0, HALF - 6.0)
		var h := height_at(x, z)
		if h < 0.2:
			continue
		if absf(x - RAMP_X) < 7.0 and z > 6.0:
			continue
		if _pad(x, z, HUT_CENTER, HUT_HALF) > 0.01 or _pad(x, z, TOWER_CENTER, TOWER_HALF) > 0.01:
			continue
		var r := rng.randf_range(0.5, 1.7)
		var sph := SphereMesh.new()
		sph.radius = r
		sph.height = r * 1.6
		sph.radial_segments = 6
		sph.rings = 3
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(1.0, 0.75, 1.15))
		var pos := Vector3(x, h + r * 0.2, z)
		st.append_from(sph, 0, Transform3D(basis, pos))
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var ss := SphereShape3D.new()
		ss.radius = r * 0.8
		cs.shape = ss
		body.add_child(cs)
		body.position = pos
		add_child(body)
		placed += 1
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _rock_mat
	add_child(mi)


func _build_jetty() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var deck := BoxMesh.new()
	deck.size = Vector3(2.4, 0.15, 11.0)
	var deck_pos := Vector3(RAMP_X, 0.475, JETTY_START + 5.5)
	st.append_from(deck, 0, Transform3D(Basis(), deck_pos))
	var post := BoxMesh.new()
	post.size = Vector3(0.22, 3.6, 0.22)
	for z in [JETTY_START + 0.5, JETTY_START + 4.0, JETTY_START + 7.5, JETTY_START + 10.5]:
		for sx in [-1.1, 1.1]:
			st.append_from(post, 0, Transform3D(Basis(), Vector3(RAMP_X + sx, -1.2, z)))
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _wood_mat
	add_child(mi)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = deck.size
	cs.shape = bs
	body.add_child(cs)
	body.position = deck_pos
	add_child(body)


func _build_tower() -> void:
	# Placeholder landmark; the real interior comes later.
	var c := Vector3(TOWER_CENTER.x, PLATEAU, TOWER_CENTER.y)
	var shaft := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = 3.0
	cyl.top_radius = 2.2
	cyl.height = 24.0
	cyl.radial_segments = 12
	shaft.mesh = cyl
	shaft.material_override = Tex.material(Tex.bricks(), 1.0, 1.25)
	shaft.position = c + Vector3(0, 12.0, 0)
	add_child(shaft)

	var gallery := MeshInstance3D.new()
	var gm := CylinderMesh.new()
	gm.bottom_radius = 3.1
	gm.top_radius = 3.1
	gm.height = 0.5
	gm.radial_segments = 12
	gallery.mesh = gm
	gallery.material_override = Tex.material(Tex.rough(), 1.0, 0.8)
	gallery.position = c + Vector3(0, 24.2, 0)
	add_child(gallery)

	var lamp := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.bottom_radius = 1.4
	lm.top_radius = 1.4
	lm.height = 2.4
	lm.radial_segments = 10
	lamp.mesh = lm
	var emissive := StandardMaterial3D.new()
	emissive.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	emissive.albedo_color = Color.WHITE
	lamp.material_override = emissive
	lamp.position = c + Vector3(0, 25.7, 0)
	add_child(lamp)

	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 2.8
	shape.height = 24.0
	cs.shape = shape
	body.add_child(cs)
	body.position = c + Vector3(0, 12.0, 0)
	add_child(body)

	_beam = Node3D.new()
	_beam.position = c + Vector3(0, 25.7, 0)
	var spot := SpotLight3D.new()
	spot.spot_range = 90.0
	spot.spot_angle = 12.0
	spot.light_energy = 8.0
	spot.light_cull_mask = 1
	spot.rotation_degrees.x = -5.0
	_beam.add_child(spot)
	add_child(_beam)


func _build_boundary() -> void:
	# Invisible walls at the edge of the terrain so nobody walks off the map.
	for side in [Vector3(HALF, 0, 0), Vector3(-HALF, 0, 0), Vector3(0, 0, HALF), Vector3(0, 0, -HALF)]:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(2.0, 60.0, 2.0 * HALF) if side.x != 0.0 else Vector3(2.0 * HALF, 60.0, 2.0)
		cs.shape = bs
		body.add_child(cs)
		body.position = side + Vector3(0, 10.0, 0)
		add_child(body)


func _process(delta: float) -> void:
	_beam.rotate_y(-0.45 * delta)
