class_name RoomKit
extends Node3D
## Building blocks for interiors. Static boxes are merged into one mesh per material and
## visual layer (one draw call each). Each face of a box can carry its own material and
## layer, so the two sides of a wall belong to the two rooms they face. Per-room layers
## let each room's lights ignore the rooms next door (no light leaking through walls
## without paying for shadows).

var _batches := {}                ## "key|layer" -> SurfaceTool
var _body: StaticBody3D

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


func _surface(mat_key: String, layer: int) -> SurfaceTool:
	var k := "%s|%d" % [mat_key, layer]
	if not _batches.has(k):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_batches[k] = st
	return _batches[k]


## Adds one box. `faces` maps "px","nx","py","ny","pz","nz" to [material key, layer];
## faces not listed use `base`. Axis-aligned boxes get world-space UVs so a texture
## runs on unbroken across neighbouring boxes. `yaw` rotates props around Y.
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
		var tile := Mats.tile_of(spec[0]) if (Mats.TABLE[spec[0]] as Dictionary).get("tex", "") != "" else 1.0
		var st := _surface(spec[0], spec[1])
		var wn := basis * n
		var pts: Array[Vector3] = []
		var uvs: Array[Vector2] = []
		for c in corners:
			var world := basis * c + center
			pts.append(world)
			var uv_src := (c + center) if yaw == 0.0 else (c + half)
			uvs.append(Vector2(uv_src.dot(a), -uv_src.dot(b)) / tile)
		# Godot treats clockwise triangles (seen from outside) as front faces.
		var order := [0, 1, 2, 0, 2, 3]
		if (pts[1] - pts[0]).cross(pts[2] - pts[0]).dot(wn) > 0.0:
			order = [0, 2, 1, 0, 3, 2]
		for i in order:
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


func flush() -> void:
	for k in _batches:
		var st: SurfaceTool = _batches[k]
		st.generate_tangents()
		var parts: PackedStringArray = (k as String).split("|")
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = Mats.get_mat(parts[0])
		mi.layers = int(parts[1])
		add_child(mi)
	_batches.clear()


## Standalone box mesh with tile-scaled UVs, for things that move (door leaves).
static func box_mesh(size: Vector3, mat_key: String) -> ArrayMesh:
	var textured: bool = (Mats.TABLE[mat_key] as Dictionary).get("tex", "") != ""
	var tile := Mats.tile_of(mat_key) if textured else 1.0
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
