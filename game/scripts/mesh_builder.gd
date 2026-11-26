class_name MeshBuilder
extends RefCounted
## Builds one mesh from quads, prisms and ring sectors, and keeps the same triangles for collision.
## Triangles are wound to face along the normal they are given, so callers never think about winding.

var st := SurfaceTool.new()
var faces := PackedVector3Array()       ## collision triangles (when `collide` is on)
var collide := true
var _empty := true


func _init(collides := true) -> void:
	collide = collides
	st.begin(Mesh.PRIMITIVE_TRIANGLES)


static func _uv(p: Vector3, n: Vector3) -> Vector2:
	var a := n.abs()
	if a.y >= a.x and a.y >= a.z:
		return Vector2(p.x, p.z)
	if a.x >= a.z:
		return Vector2(p.z, -p.y)
	return Vector2(p.x, -p.y)


## One triangle with a normal per corner; the winding follows the average normal (Godot's front faces are clockwise).
func tri(a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3) -> void:
	if (b - a).cross(c - a).dot(na + nb + nc) > 0.0:
		var t := b
		b = c
		c = t
		var tn := nb
		nb = nc
		nc = tn
	for k in 3:
		var p: Vector3 = [a, b, c][k]
		var n: Vector3 = [na, nb, nc][k]
		st.set_normal(n)
		st.set_uv(_uv(p, n))
		st.add_vertex(p)
	if collide:
		faces.append(a)
		faces.append(b)
		faces.append(c)
	_empty = false


func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	tri(a, b, c, n, n, n)
	tri(a, c, d, n, n, n)


func quad_n(a: Vector3, b: Vector3, c: Vector3, d: Vector3, na: Vector3, nb: Vector3, nc: Vector3, nd: Vector3) -> void:
	tri(a, b, c, na, nb, nc)
	tri(a, c, d, na, nc, nd)


## A flat polygon (convex, in order) facing n.
func poly(pts: Array, n: Vector3) -> void:
	for i in range(1, pts.size() - 1):
		tri(pts[0], pts[i], pts[i + 1], n, n, n)


## A vertical prism: a convex polygon (Vector3s, y ignored) from y0 up to y1, with its sides.
func prism(pts: Array, y0: float, y1: float, top := true, bottom := true) -> void:
	var lo: Array = pts.map(func(p: Vector3) -> Vector3: return Vector3(p.x, y0, p.z))
	var hi: Array = pts.map(func(p: Vector3) -> Vector3: return Vector3(p.x, y1, p.z))
	if top:
		poly(hi, Vector3.UP)
	if bottom:
		poly(lo, Vector3.DOWN)
	var c := Vector3.ZERO
	for p in pts:
		c += p
	c /= pts.size()
	for i in pts.size():
		var j := (i + 1) % pts.size()
		var e: Vector3 = hi[j] - hi[i]
		var n := Vector3(e.z, 0, -e.x).normalized()
		if n.dot(Vector3(hi[i].x - c.x, 0, hi[i].z - c.z)) < 0.0:
			n = -n
		quad(lo[i], lo[j], hi[j], hi[i], n)


## A box with any transform.
func box(xf: Transform3D, size: Vector3) -> void:
	var h := size / 2.0
	var b := xf.basis
	for axis in 3:
		for s in [-1.0, 1.0]:
			var n := Vector3.ZERO
			n[axis] = s
			var u := Vector3.ZERO
			var v := Vector3.ZERO
			u[(axis + 1) % 3] = 1.0
			v[(axis + 2) % 3] = 1.0
			var c := n * h[axis]
			var du := u * h[(axis + 1) % 3]
			var dv := v * h[(axis + 2) % 3]
			quad(xf * (c - du - dv), xf * (c + du - dv), xf * (c + du + dv), xf * (c - du + dv), (b * n).normalized())


## Polar point: angle in degrees from +Z toward +X, radius r, height y.
static func polar(a_deg: float, r: float, y: float) -> Vector3:
	var a := deg_to_rad(a_deg)
	return Vector3(r * sin(a), y, r * cos(a))


static func radial(a_deg: float) -> Vector3:
	var a := deg_to_rad(a_deg)
	return Vector3(sin(a), 0, cos(a))


## A ring sector (annulus piece) as a solid from y0 to y1. Angles in degrees, a0 < a1; r0 may be 0 (a pie slice).
func ring_sector(r0: float, r1: float, a0: float, a1: float, y0: float, y1: float, step := 7.5, ends := true) -> void:
	var n := maxi(1, int(ceil((a1 - a0) / step)))
	for k in n:
		var b0 := a0 + (a1 - a0) * k / n
		var b1 := a0 + (a1 - a0) * (k + 1) / n
		if r0 > 0.001:
			quad(polar(b0, r0, y1), polar(b1, r0, y1), polar(b1, r1, y1), polar(b0, r1, y1), Vector3.UP)
			quad(polar(b0, r0, y0), polar(b1, r0, y0), polar(b1, r1, y0), polar(b0, r1, y0), Vector3.DOWN)
			quad_n(polar(b0, r0, y0), polar(b1, r0, y0), polar(b1, r0, y1), polar(b0, r0, y1),
					-radial(b0), -radial(b1), -radial(b1), -radial(b0))
		else:
			tri(Vector3(0, y1, 0), polar(b0, r1, y1), polar(b1, r1, y1), Vector3.UP, Vector3.UP, Vector3.UP)
			tri(Vector3(0, y0, 0), polar(b0, r1, y0), polar(b1, r1, y0), Vector3.DOWN, Vector3.DOWN, Vector3.DOWN)
		quad_n(polar(b0, r1, y0), polar(b1, r1, y0), polar(b1, r1, y1), polar(b0, r1, y1),
				radial(b0), radial(b1), radial(b1), radial(b0))
	if ends and a1 - a0 < 359.9:
		for e in [[a0, -1.0], [a1, 1.0]]:
			var t: Vector3 = radial(e[0] + 90.0) * e[1]
			quad(polar(e[0], r0, y0), polar(e[0], r1, y0), polar(e[0], r1, y1), polar(e[0], r0, y1), t)


## A vertical ribbon along a curve: pts are the bottom points, h the height. Collision walls (rails) and bands.
func ribbon(pts: Array, h: float) -> void:
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var e := b - a
		var n := Vector3(e.z, 0, -e.x).normalized()
		quad(a, b, b + Vector3(0, h, 0), a + Vector3(0, h, 0), n)


func is_empty() -> bool:
	return _empty


func instance(mat: Material, layers := 1) -> MeshInstance3D:
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.layers = layers
	return mi


static func body_from(tris: PackedVector3Array) -> StaticBody3D:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(tris)
	cs.shape = shape
	body.add_child(cs)
	return body
