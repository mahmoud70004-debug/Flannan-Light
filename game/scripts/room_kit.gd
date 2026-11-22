class_name RoomKit
extends Node3D
## Building blocks for interiors. Static geometry is merged into one mesh per material and
## visual layer (one draw call each). Each face of a box can carry its own material and
## layer, so the two sides of a wall belong to the two rooms they face. Per-room layers
## let each room's lights ignore the rooms next door (no light leaking through walls
## without paying for shadows).

var _batches := {}                ## "key|layer" -> SurfaceTool
var _body: StaticBody3D
var ceilings: Node3D              ## ceiling meshes, so a debug view can hide them
var cull_items: Array[MeshInstance3D] = []   ## meshes shown or hidden by which rooms the player can see

const FACE_AXES := {
	"px": [Vector3.RIGHT, Vector3.BACK, Vector3.UP],
	"nx": [Vector3.LEFT, Vector3.BACK, Vector3.UP],
	"py": [Vector3.UP, Vector3.RIGHT, Vector3.BACK],
	"ny": [Vector3.DOWN, Vector3.RIGHT, Vector3.BACK],
	"pz": [Vector3.BACK, Vector3.RIGHT, Vector3.UP],
	"nz": [Vector3.FORWARD, Vector3.RIGHT, Vector3.UP],
}


func _ready_kit() -> void:
	_body = StaticBody3D.new()
	_body.collision_layer = 1
	add_child(_body)
	ceilings = Node3D.new()
	add_child(ceilings)


func _surface(mat_key: String, layer: int, tag := "") -> SurfaceTool:
	var k := "%s|%d|%s" % [mat_key, layer, tag]
	if not _batches.has(k):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_batches[k] = st
	return _batches[k]


## Adds one box. `faces` maps "px","nx","py","ny","pz","nz" to [material key, layer];
## faces not listed use `base` (an empty array skips the face). Axis-aligned boxes get
## world-space UVs so a texture runs on unbroken across neighbouring boxes. `yaw` rotates
## props around Y.
func box(center: Vector3, size: Vector3, base: Array, faces := {}, collide := true, yaw := 0.0) -> void:
	var basis := Basis(Vector3.UP, yaw)
	var half := size * 0.5
	for f in FACE_AXES:
		var spec: Array = faces.get(f, base)
		if spec.is_empty():
			continue
		var ax: Array = FACE_AXES[f]
		var n: Vector3 = ax[0]
		var a: Vector3 = ax[1]
		var b: Vector3 = ax[2]
		var cf := n * (half * n.abs()).length()           # local face centre offset
		var ha := (half * a.abs()).length()
		var hb := (half * b.abs()).length()
		var corners: Array[Vector3] = [
			cf - a * ha - b * hb, cf + a * ha - b * hb, cf + a * ha + b * hb, cf - a * ha + b * hb]
		var tile := Mats.uv_tile(spec[0])
		var st := _surface(Mats.batch_key(spec[0]), spec[1], spec[2] if spec.size() > 2 else "")
		var col := Mats.color_of(spec[0]) if Mats.is_plain(spec[0]) else Color.WHITE
		var tinted := Mats.is_plain(spec[0])
		var wn := basis * n
		var pts: Array[Vector3] = []
		var uvs: Array[Vector2] = []
		for c in corners:
			pts.append(basis * c + center)
			var uv_src := (c + center) if yaw == 0.0 else (c + half)
			uvs.append(Vector2(uv_src.dot(a), -uv_src.dot(b)) / tile)
		# Godot treats clockwise triangles (seen from outside) as front faces.
		var order := [0, 1, 2, 0, 2, 3]
		if (pts[1] - pts[0]).cross(pts[2] - pts[0]).dot(wn) > 0.0:
			order = [0, 2, 1, 0, 3, 2]
		for i in order:
			if tinted:
				st.set_color(col)
			st.set_normal(wn)
			st.set_uv(uvs[i])
			st.add_vertex(pts[i])
	if collide:
		var shape := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		shape.shape = bs
		shape.transform = Transform3D(basis, center)
		_body.add_child(shape)


## A flat rectangle facing `normal`; UVs run 0..1 (v = 0 at the top edge unless flipped).
## Used for stains and fake ambient-occlusion strips.
func quad(center: Vector3, normal: Vector3, up: Vector3, w: float, h: float, mat_key: String, layer: int, flip_v := false) -> void:
	var right := up.cross(normal).normalized()
	var u := right * (w * 0.5)
	var v := up * (h * 0.5)
	var pts: Array[Vector3] = [center - u - v, center + u - v, center + u + v, center - u + v]
	var uvs: Array[Vector2] = [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	if flip_v:
		uvs = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	var order := [0, 1, 2, 0, 2, 3]
	if (pts[1] - pts[0]).cross(pts[2] - pts[0]).dot(normal) > 0.0:
		order = [0, 2, 1, 0, 3, 2]
	var st := _surface(Mats.batch_key(mat_key), layer)
	var tinted := Mats.is_plain(mat_key)
	for i in order:
		if tinted:
			st.set_color(Mats.color_of(mat_key))
		st.set_normal(normal)
		st.set_uv(uvs[i])
		st.add_vertex(pts[i])


## Meshes from res://assets/models/props (built in Blender, see tools/blender): vertex-coloured, merged straight into
## the room's batches so they cost no extra draw calls. Cached as raw arrays so no resource stays loaded.
static var _models := {}


static func _model_data(model_name: String) -> Array:
	if _models.has(model_name):
		return _models[model_name]
	var out: Array = []
	var path := "res://assets/models/props/%s.glb" % model_name
	if ResourceLoader.exists(path):
		var inst := (load(path) as PackedScene).instantiate()
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			var xf := Transform3D()
			var n: Node = mi
			while n and n != inst:
				xf = (n as Node3D).transform * xf
				n = n.get_parent()
			var mesh: Mesh = (mi as MeshInstance3D).mesh
			for sidx in mesh.get_surface_count():
				var arr := mesh.surface_get_arrays(sidx)
				var mat := mesh.surface_get_material(sidx)
				var group := "g_" + (mat.resource_name if mat and mat.resource_name != "" else "matte")
				if not (group in ["g_matte", "g_gloss", "g_metal"]):
					group = "g_matte"
				out.append({"group": group, "v": arr[Mesh.ARRAY_VERTEX], "n": arr[Mesh.ARRAY_NORMAL], "c": arr[Mesh.ARRAY_COLOR], "i": arr[Mesh.ARRAY_INDEX], "xf": xf})
		inst.free()
	_models[model_name] = out
	return out


var placed_models: Array = []        ## [{name, aabb}] every model added, so tests can check it has a collider

## Adds a model at `center`, turned by `basis`. Returns false (and adds nothing) if the model is missing.
func model(model_name: String, center: Vector3, basis: Basis, layer: int) -> bool:
	var data := _model_data(model_name)
	if data.is_empty():
		return false
	var lo := Vector3(1e9, 1e9, 1e9)
	var hi := Vector3(-1e9, -1e9, -1e9)
	for s in data:
		var st := _surface(s["group"], layer)
		var xf: Transform3D = s["xf"]
		var nb := basis * xf.basis
		var verts: PackedVector3Array = s["v"]
		var norms: PackedVector3Array = s["n"]
		var cols = s["c"]
		var idx: PackedInt32Array = s["i"]
		for k in idx.size():
			var vi := idx[k]
			st.set_color(cols[vi] if cols is PackedColorArray else Color(0.5, 0.5, 0.5))
			st.set_normal((nb * norms[vi]).normalized())
			st.set_uv(Vector2.ZERO)
			var wp := center + basis * (xf * verts[vi])
			st.add_vertex(wp)
			lo = lo.min(wp)
			hi = hi.max(wp)
	placed_models.append({"name": model_name, "aabb": AABB(lo, hi - lo)})
	return true


## Invisible collision for a prop.
func collider(center: Vector3, size: Vector3, yaw := 0.0) -> void:
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	shape.transform = Transform3D(Basis(Vector3.UP, yaw), center)
	_body.add_child(shape)


## A lumpy ball (a bag of rubbish): a squashed sphere, `squash` flattens it, `lump` wobbles the surface.
func ball(center: Vector3, radius: float, mat_key: String, layer: int, squash := 0.8, lump := 0.12, seed_i := 1, segs := 10, rings := 6) -> void:
	var st := _surface(Mats.batch_key(mat_key), layer)
	var col := Mats.color_of(mat_key)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_i
	var phase := [rng.randf() * 6.28, rng.randf() * 6.28, rng.randf() * 6.28]
	var pts := []
	for r in rings + 1:
		var row := []
		var phi := PI * float(r) / float(rings)
		for i in segs:
			var th := TAU * float(i) / float(segs)
			var wob := 1.0 + lump * (sin(th * 2.0 + phase[0]) * 0.5 + sin(phi * 3.0 + phase[1]) * 0.5)
			var d := Vector3(sin(phi) * cos(th), cos(phi) * squash, sin(phi) * sin(th))
			row.append(center + d * radius * wob)
		pts.append(row)
	for r in rings:
		for i in segs:
			var a: Vector3 = pts[r][i]
			var b: Vector3 = pts[r][(i + 1) % segs]
			var c: Vector3 = pts[r + 1][(i + 1) % segs]
			var d2: Vector3 = pts[r + 1][i]
			var n := ((a + b + c + d2) * 0.25 - center).normalized()
			_tri(st, a, b, c, n, col)
			_tri(st, a, c, d2, n, col)


## A cylinder or cone (top_radius < 0 keeps it straight), standing on its centre point.
func cyl(center: Vector3, radius: float, height: float, mat_key: String, layer: int, top_radius := -1.0, sides := 14) -> void:
	var st := _surface(Mats.batch_key(mat_key), layer)
	var col := Mats.color_of(mat_key)
	var tr := radius if top_radius < 0.0 else top_radius
	var y0 := -height * 0.5
	var y1 := height * 0.5
	for i in sides:
		var a0 := TAU * float(i) / float(sides)
		var a1 := TAU * float(i + 1) / float(sides)
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var b0 := center + d0 * radius + Vector3(0, y0, 0)
		var b1 := center + d1 * radius + Vector3(0, y0, 0)
		var t0 := center + d0 * tr + Vector3(0, y1, 0)
		var t1 := center + d1 * tr + Vector3(0, y1, 0)
		var n := ((d0 + d1) * 0.5).normalized()
		_tri(st, b0, b1, t1, n, col)
		_tri(st, b0, t1, t0, n, col)
		if tr > 0.001:
			_tri(st, center + Vector3(0, y1, 0), t0, t1, Vector3.UP, col)
		_tri(st, center + Vector3(0, y0, 0), b1, b0, Vector3.DOWN, col)


## One triangle, wound so it faces along `n` (Godot's front faces are clockwise).
func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3, col: Color) -> void:
	var pts := [a, b, c]
	if (b - a).cross(c - a).dot(n) > 0.0:
		pts = [a, c, b]
	for p in pts:
		st.set_color(col)
		st.set_normal(n)
		st.set_uv(Vector2.ZERO)
		st.add_vertex(p)


func flush() -> void:
	for k in _batches:
		var st: SurfaceTool = _batches[k]
		var parts: PackedStringArray = (k as String).split("|")
		if not (parts[0].begins_with("g_") or parts[0].begins_with("_")):
			st.generate_tangents()                      # only textured batches have normal maps
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = Mats.get_mat(parts[0])
		mi.layers = int(parts[1])
		if parts[0] == "_stain" or parts[0] == "_ao":
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if parts[0] == "ceiling":
			ceilings.add_child(mi)
		else:
			add_child(mi)
		cull_items.append(mi)
	_batches.clear()


## Standalone box mesh with tile-scaled UVs, for things that move (door leaves).
static func box_mesh(size: Vector3, mat_key: String) -> ArrayMesh:
	var tile := Mats.uv_tile(mat_key)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := size * 0.5
	for f in FACE_AXES:
		var ax: Array = FACE_AXES[f]
		var n: Vector3 = ax[0]
		var a: Vector3 = ax[1]
		var b: Vector3 = ax[2]
		var cf := n * (half * n.abs()).length()
		var ha := (half * a.abs()).length()
		var hb := (half * b.abs()).length()
		var pts: Array[Vector3] = [cf - a * ha - b * hb, cf + a * ha - b * hb, cf + a * ha + b * hb, cf - a * ha + b * hb]
		var order := [0, 1, 2, 0, 2, 3]
		if (pts[1] - pts[0]).cross(pts[2] - pts[0]).dot(n) > 0.0:
			order = [0, 2, 1, 0, 3, 2]
		for i in order:
			var c := pts[i] + half
			st.set_normal(n)
			st.set_uv(Vector2(c.dot(a), -c.dot(b)) / tile)
			st.add_vertex(pts[i])
	st.generate_tangents()
	return st.commit()
