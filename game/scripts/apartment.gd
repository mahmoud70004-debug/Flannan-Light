class_name Apartment
extends RoomKit
## Martin's flat. A T-shaped hall (front hall, a door, the long back hall, a west leg) with
## thirteen rooms off it, so nothing shows the whole flat at once. Everything is built from
## data in code: cells (rooms) on a grid, walls derived from where cells touch, and a list of
## openings (doors, arches, windows). +X east, -Z north, y up, floor at y = 0. The front door
## is on the south side; the landline stands at the far north end of the back hall.

signal said(text: String)             ## a line of Martin's inner voice for the HUD

const H := 2.5
const DOOR_H := 2.05
const DOOR_W := 0.9                   ## clear opening of every interior door
const T_IN := 0.12
const T_EXT := 0.22
const X_W := -6.6
const X_E := 5.0
const Z_S := 0.0
const Z_N := -10.0

const L_HALLF := 1 << 1
const L_HALLB := 1 << 2
const L_BATH := 1 << 3
const L_DADS := 1 << 4
const L_BED := 1 << 5
const L_SPARE := 1 << 6
const L_UTIL := 1 << 7
const L_KIT := 1 << 8
const L_LIV := 1 << 9
const L_BOX := 1 << 10
const L_STUDY := 1 << 11
const L_JAMB := 1 << 12              ## door/window reveals: lit by every lamp, since two rooms see them

## cell -> {r: [x0, x1, z0, z1] on the wall centre lines (z0 is the north edge), floor, wall, layer}
const CELLS := {
	"hall_front": {"r": [-1.0, 0.4, -4.6, 0.0], "floor": "floor_hall", "wall": "wall", "layer": L_HALLF},
	"hall_back": {"r": [-1.0, 0.4, -10.0, -4.6], "floor": "floor_hall", "wall": "wall", "layer": L_HALLB},
	"hall_w": {"r": [-6.6, -1.0, -7.4, -6.0], "floor": "floor_hall", "wall": "wall", "layer": L_HALLB},
	"bath": {"r": [-3.4, -1.0, -2.6, 0.0], "floor": "tile", "wall": "wall_damp", "layer": L_BATH},
	"dads": {"r": [-3.4, -1.0, -6.0, -2.6], "floor": "floor_hall", "wall": "wall", "layer": L_DADS},
	"bedroom": {"r": [-6.6, -3.4, -6.0, -2.6], "floor": "floor_wood", "wall": "wall", "layer": L_BED},
	"dressing": {"r": [-6.6, -3.4, -2.6, 0.0], "floor": "floor_wood", "wall": "wall", "layer": L_BED},
	"spare": {"r": [-6.6, -3.4, -10.0, -7.4], "floor": "floor_wood", "wall": "wall", "layer": L_SPARE},
	"utility": {"r": [-3.4, -1.0, -10.0, -7.4], "floor": "tile", "wall": "wall_damp", "layer": L_UTIL},
	"kitchen": {"r": [0.4, 5.0, -3.0, 0.0], "floor": "tile", "wall": "wall", "layer": L_KIT},
	"living": {"r": [0.4, 5.0, -8.0, -3.0], "floor": "floor_wood", "wall": "wall", "layer": L_LIV},
	"box": {"r": [0.4, 2.6, -10.0, -8.0], "floor": "floor_hall", "wall": "wall", "layer": L_BOX},
	"study": {"r": [2.6, 5.0, -10.0, -8.0], "floor": "floor_wood", "wall": "wall", "layer": L_STUDY},
}

## Openings. axis "x": a wall running along Z at x = fixed; "z": along X at z = fixed. c is the
## centre along the wall. Doors: hinge "lo"/"hi" end, swing "neg"/"pos" side, open at start.
const OPENINGS := [
	{"kind": "front", "axis": "z", "fixed": 0.0, "c": -0.3, "w": 0.95},
	{"kind": "door", "name": "hall", "axis": "z", "fixed": -4.6, "c": -0.3, "w": 0.9, "hinge": "lo", "swing": "neg", "open": false},
	{"kind": "door", "name": "bath", "axis": "x", "fixed": -1.0, "c": -1.2, "w": 0.9, "hinge": "hi", "swing": "neg", "open": false},
	{"kind": "door", "name": "dads", "axis": "z", "fixed": -6.0, "c": -2.2, "w": 0.9, "hinge": "lo", "swing": "pos", "open": false},
	{"kind": "door", "name": "bedroom", "axis": "z", "fixed": -6.0, "c": -5.0, "w": 0.9, "hinge": "hi", "swing": "pos", "open": false},
	{"kind": "door", "name": "dressing", "axis": "z", "fixed": -2.6, "c": -3.95, "w": 0.9, "hinge": "lo", "swing": "neg", "open": false},
	{"kind": "door", "name": "spare", "axis": "z", "fixed": -7.4, "c": -5.0, "w": 0.9, "hinge": "lo", "swing": "neg", "open": false},
	{"kind": "door", "name": "utility", "axis": "x", "fixed": -1.0, "c": -8.7, "w": 0.9, "hinge": "hi", "swing": "neg", "open": false},
	{"kind": "door", "name": "kitchen", "axis": "x", "fixed": 0.4, "c": -1.5, "w": 0.9, "hinge": "hi", "swing": "pos", "open": false},
	{"kind": "door", "name": "living", "axis": "x", "fixed": 0.4, "c": -6.0, "w": 0.9, "hinge": "lo", "swing": "pos", "open": true},
	{"kind": "door", "name": "box", "axis": "x", "fixed": 0.4, "c": -9.0, "w": 0.9, "hinge": "hi", "swing": "pos", "open": false},
	{"kind": "door", "name": "study", "axis": "z", "fixed": -8.0, "c": 3.8, "w": 0.9, "hinge": "lo", "swing": "neg", "open": false},
	{"kind": "arch", "axis": "x", "fixed": -1.0, "c": -6.7, "w": 1.4},
	{"kind": "arch", "axis": "z", "fixed": -3.0, "c": 3.4, "w": 1.2},
	# Windows: sill and top heights, curtains optional.
	{"kind": "window", "axis": "x", "fixed": -6.6, "c": -4.3, "w": 1.4, "sill": 0.9, "top": 2.05, "cur": true},
	{"kind": "window", "axis": "z", "fixed": 0.0, "c": -5.0, "w": 0.8, "sill": 1.0, "top": 2.05, "cur": false},
	{"kind": "window", "axis": "x", "fixed": -6.6, "c": -8.7, "w": 1.0, "sill": 1.0, "top": 2.0, "cur": true},
	{"kind": "window", "axis": "z", "fixed": -10.0, "c": -5.0, "w": 1.0, "sill": 1.0, "top": 2.0, "cur": false},
	{"kind": "window", "axis": "x", "fixed": -6.6, "c": -6.7, "w": 0.6, "sill": 1.0, "top": 2.0, "cur": false},
	{"kind": "window", "axis": "z", "fixed": -10.0, "c": -0.3, "w": 0.6, "sill": 1.0, "top": 2.0, "cur": false},
	{"kind": "window", "axis": "z", "fixed": -10.0, "c": 1.5, "w": 0.8, "sill": 1.1, "top": 2.0, "cur": false},
	{"kind": "window", "axis": "z", "fixed": -10.0, "c": 3.8, "w": 0.9, "sill": 1.0, "top": 2.05, "cur": true},
	{"kind": "window", "axis": "x", "fixed": 5.0, "c": -9.0, "w": 0.8, "sill": 1.1, "top": 2.0, "cur": false},
	{"kind": "window", "axis": "x", "fixed": 5.0, "c": -5.5, "w": 1.8, "sill": 0.9, "top": 2.05, "cur": true},
	{"kind": "window", "axis": "x", "fixed": 5.0, "c": -1.5, "w": 1.0, "sill": 0.95, "top": 2.05, "cur": false},
	{"kind": "window", "axis": "z", "fixed": 0.0, "c": 2.7, "w": 1.0, "sill": 1.0, "top": 2.05, "cur": false},
]

## Ceiling lamps: [cell, x, z, colour, energy, range, fitting]  (fitting: "bulb", "shade")
const LAMPS := [
	["hall_front", -0.3, -2.3, Color(1.0, 0.80, 0.55), 0.9, 4.2, "bulb"],
	["hall_back", -0.3, -6.2, Color(1.0, 0.80, 0.55), 0.8, 4.2, "shade"],
	["hall_back", -0.3, -9.0, Color(1.0, 0.76, 0.5), 0.6, 3.6, "bulb"],
	["hall_w", -3.8, -6.7, Color(1.0, 0.78, 0.52), 0.8, 4.6, "shade"],
	["bath", -2.2, -1.3, Color(0.86, 0.93, 1.0), 1.0, 3.4, "bulb"],
	["dads", -2.2, -4.3, Color(1.0, 0.74, 0.5), 0.8, 3.6, "bulb"],
	["bedroom", -5.0, -4.3, Color(1.0, 0.78, 0.55), 0.9, 4.2, "shade"],
	["dressing", -5.0, -1.3, Color(1.0, 0.8, 0.56), 0.7, 3.3, "bulb"],
	["spare", -5.0, -8.7, Color(1.0, 0.78, 0.55), 0.8, 3.8, "shade"],
	["utility", -2.2, -8.7, Color(0.9, 0.95, 1.0), 0.7, 3.2, "bulb"],
	["kitchen", 2.7, -1.5, Color(0.92, 0.97, 0.88), 0.95, 5.0, "bulb"],
	["living", 2.7, -5.5, Color(1.0, 0.8, 0.58), 1.0, 5.6, "shade"],
	["box", 1.5, -9.0, Color(1.0, 0.74, 0.5), 0.55, 3.0, "bulb"],
	["study", 3.8, -9.0, Color(1.0, 0.78, 0.55), 0.6, 3.2, "bulb"],
]

## Light switches: [cell, x, z, facing (direction the plate looks, into the room)]
const SWITCHES := [
	["hall_front", 0.33, -0.55, Vector3(-1, 0, 0)],
	["hall_back", 0.33, -5.2, Vector3(-1, 0, 0)],
	["hall_w", -2.0, -7.33, Vector3(0, 0, 1)],
	["bath", -1.07, -0.45, Vector3(-1, 0, 0)],
	["dads", -1.5, -5.93, Vector3(0, 0, 1)],
	["bedroom", -4.0, -5.93, Vector3(0, 0, 1)],
	["dressing", -5.2, -2.53, Vector3(0, 0, 1)],
	["spare", -4.0, -7.47, Vector3(0, 0, -1)],
	["utility", -1.07, -9.3, Vector3(-1, 0, 0)],
	["kitchen", 0.47, -2.1, Vector3(1, 0, 0)],
	["living", 0.47, -5.3, Vector3(1, 0, 0)],
	["box", 0.47, -9.5, Vector3(1, 0, 0)],
	["study", 3.1, -8.07, Vector3(0, 0, -1)],
]

var doors := {}                        ## name -> Door
var door_info := {}                    ## name -> {center, normal (toward the swing side), w}
var lamps := {}                        ## cell -> Array of {light, bulb}
var front_door: Interactable
var phone: Interactable
var _panes: Array[MeshInstance3D] = []
var _lines := {}                       ## wall line key -> side records (wall generation)
var viewer: Node3D                     ## the player: only rooms they can see through open doors are drawn
var _links: Array = []                 ## [cell_a, cell_b, door name or ""] for every way through a wall
var _cull_cell := ""
var _cull_dirty := true


func _ready() -> void:
	_ready_kit()
	_floors_and_ceilings()
	_walls()
	_lamps_and_switches()
	_collision_floor()
	Furnishings.furnish(self)
	flush()


# --- cell helpers ------------------------------------------------------------

func layer_of(cell: String) -> int:
	return CELLS[cell]["layer"] if cell != "" else 0


func rect_of(cell: String) -> Array:
	return CELLS[cell]["r"]


## Interior bounds [x0, x1, z0, z1] of a cell: the cell minus half the walls around it.
func ib(cell: String) -> Array:
	var r: Array = CELLS[cell]["r"]
	return [
		r[0] + (T_EXT if is_equal_approx(r[0], X_W) else T_IN) * 0.5,
		r[1] - (T_EXT if is_equal_approx(r[1], X_E) else T_IN) * 0.5,
		r[2] + (T_EXT if is_equal_approx(r[2], Z_N) else T_IN) * 0.5,
		r[3] - (T_EXT if is_equal_approx(r[3], Z_S) else T_IN) * 0.5]


func cell_at(p: Vector3) -> String:
	for name in CELLS:
		var r: Array = CELLS[name]["r"]
		if p.x >= r[0] and p.x <= r[1] and p.z >= r[2] and p.z <= r[3]:
			return name
	return ""


func _spec(cell: String) -> Array:
	if cell == "":
		return []
	return [CELLS[cell]["wall"], CELLS[cell]["layer"]]


# --- floors, ceilings ------------------------------------------------------------

func _floors_and_ceilings() -> void:
	for name in CELLS:
		var c: Dictionary = CELLS[name]
		var r: Array = c["r"]
		var w: float = r[1] - r[0]
		var d: float = r[3] - r[2]
		var cx: float = (r[0] + r[1]) * 0.5
		var cz: float = (r[2] + r[3]) * 0.5
		box(Vector3(cx, -0.05, cz), Vector3(w, 0.1, d), [], {"py": [c["floor"], c["layer"]]}, false)
		box(Vector3(cx, H + 0.05, cz), Vector3(w, 0.1, d), [], {"ny": ["ceiling", c["layer"]]}, false)


func _collision_floor() -> void:
	for y in [-0.2, H + 0.2]:
		var shape := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(12.5, 0.4, 11.0)
		shape.shape = bs
		shape.position = Vector3(-0.8, y, -5.0)
		_body.add_child(shape)


# --- walls from cells ------------------------------------------------------------

func _add_rec(axis: String, fixed: float, a0: float, a1: float, side: int, cell: String) -> void:
	var key := "%s:%.3f" % [axis, fixed]
	if not _lines.has(key):
		_lines[key] = {"axis": axis, "fixed": fixed, "recs": []}
	(_lines[key]["recs"] as Array).append({"a0": a0, "a1": a1, "side": side, "cell": cell})


func _walls() -> void:
	for name in CELLS:
		var r: Array = CELLS[name]["r"]
		_add_rec("x", r[0], r[2], r[3], 1, name)       # west edge: the room lies on the +x side
		_add_rec("x", r[1], r[2], r[3], -1, name)
		_add_rec("z", r[2], r[0], r[1], 1, name)       # north edge: the room lies on the +z side
		_add_rec("z", r[3], r[0], r[1], -1, name)
	for key in _lines:
		var line: Dictionary = _lines[key]
		var pts: Array = []
		for rec in line["recs"]:
			for v in [rec["a0"], rec["a1"]]:
				var known := false
				for p in pts:
					if is_equal_approx(p, v):
						known = true
				if not known:
					pts.append(v)
		pts.sort()
		for i in range(pts.size() - 1):
			var b0: float = pts[i]
			var b1: float = pts[i + 1]
			var mid := (b0 + b1) * 0.5
			var neg := ""
			var pos := ""
			for rec in line["recs"]:
				if mid > rec["a0"] and mid < rec["a1"]:
					if rec["side"] < 0:
						neg = rec["cell"]
					else:
						pos = rec["cell"]
			if neg == "" and pos == "":
				continue
			var ops: Array = []
			for o in OPENINGS:
				if o["axis"] == line["axis"] and is_equal_approx(o["fixed"], line["fixed"]) and o["c"] > b0 and o["c"] < b1:
					ops.append(o)
			var t := T_EXT if (neg == "" or pos == "") else T_IN
			_wall_run(line["axis"], line["fixed"], b0, b1, t, ops, neg, pos)


func _wall_run(axis: String, fixed: float, a0: float, a1: float, t: float, ops: Array, neg: String, pos: String) -> void:
	var neg_spec := _spec(neg)
	var pos_spec := _spec(pos)
	var edge: Array = [] if (neg_spec.is_empty() and pos_spec.is_empty()) else ["trim", L_JAMB]   # painted reveals
	var faces := {}
	if axis == "x":
		faces = {"nx": neg_spec, "px": pos_spec, "pz": edge, "nz": edge, "py": edge, "ny": edge}
	else:
		faces = {"nz": neg_spec, "pz": pos_spec, "px": edge, "nx": edge, "py": edge, "ny": edge}
	var sorted := ops.duplicate()
	sorted.sort_custom(func(p: Dictionary, q: Dictionary) -> bool: return p["c"] < q["c"])
	var cur := a0
	for o in sorted:
		var lo: float = o["c"] - o["w"] * 0.5
		var hi: float = o["c"] + o["w"] * 0.5
		var sill: float = o.get("sill", 0.0)
		var top: float = o.get("top", DOOR_H)
		_slab(axis, fixed, t, cur, lo, 0.0, H, faces)
		if sill > 0.0:
			_slab(axis, fixed, t, lo, hi, 0.0, sill, faces)
		_slab(axis, fixed, t, lo, hi, top, H, faces)
		cur = hi
	_slab(axis, fixed, t, cur, a1, 0.0, H, faces)

	# Dressing on each side that has a room: skirting, fake occlusion, door casings.
	var gaps: Array = []
	for o in sorted:
		if o["kind"] != "window":
			gaps.append([o["c"] - o["w"] * 0.5, o["c"] + o["w"] * 0.5])
	for side in [-1, 1]:
		var cell := neg if side < 0 else pos
		if cell == "":
			continue
		var layer := layer_of(cell)
		_wall_side_dressing(axis, fixed, t, a0, a1, side, layer, gaps)
	for o in sorted:
		if o["kind"] in ["door", "arch", "front"] and neg != "" and pos != "":
			_links.append([neg, pos, o.get("name", "")])
		match o["kind"]:
			"door":
				_make_door(o, axis, fixed, t, neg, pos)
				_casing(o, axis, fixed, t, neg, pos)
			"front":
				_make_front(o, axis, fixed, t, neg, pos)
				_casing(o, axis, fixed, t, neg, pos)
			"arch":
				_casing(o, axis, fixed, t, neg, pos)
			"window":
				_make_window(o, axis, fixed, t, neg, pos)


func _slab(axis: String, fixed: float, t: float, a0: float, a1: float, y0: float, y1: float, faces: Dictionary) -> void:
	if a1 - a0 < 0.001 or y1 - y0 < 0.001:
		return
	var mid := (a0 + a1) * 0.5
	var cy := (y0 + y1) * 0.5
	if axis == "x":
		box(Vector3(fixed, cy, mid), Vector3(t, y1 - y0, a1 - a0), [], faces)
	else:
		box(Vector3(mid, cy, fixed), Vector3(a1 - a0, y1 - y0, t), [], faces)


## A point on the wall line: `along` runs along the wall, `off` is the offset from the centre line.
func _wp(axis: String, fixed: float, along: float, y: float, off: float) -> Vector3:
	return Vector3(fixed + off, y, along) if axis == "x" else Vector3(along, y, fixed + off)


func _normal_vec(axis: String, side: int) -> Vector3:
	return Vector3(side, 0, 0) if axis == "x" else Vector3(0, 0, side)


func _wall_side_dressing(axis: String, fixed: float, t: float, a0: float, a1: float, side: int, layer: int, gaps: Array) -> void:
	var n := _normal_vec(axis, side)
	var off := side * (t * 0.5)
	# Skirting board in the gaps between door openings.
	var cur := a0
	var segs: Array = []
	for g in gaps:
		if g[0] > cur:
			segs.append([cur, g[0]])
		cur = maxf(cur, g[1])
	if a1 > cur:
		segs.append([cur, a1])
	for s in segs:
		var len: float = s[1] - s[0]
		if len < 0.05:
			continue
		var mid: float = (s[0] + s[1]) * 0.5
		var c := _wp(axis, fixed, mid, 0.055, off + side * 0.009)
		var size := Vector3(0.018, 0.11, len) if axis == "x" else Vector3(len, 0.11, 0.018)
		box(c, size, ["trim", layer], {}, false)
	# Dark gradient where the wall meets the floor and the ceiling (cheap ambient occlusion).
	for s in segs:
		quad(_wp(axis, fixed, (s[0] + s[1]) * 0.5, 0.28, off + side * 0.003), n, Vector3.UP, s[1] - s[0], 0.56, "_ao", layer)
	quad(_wp(axis, fixed, (a0 + a1) * 0.5, H - 0.18, off + side * 0.003), n, Vector3.UP, a1 - a0, 0.36, "_ao", layer, true)


func _casing(o: Dictionary, axis: String, fixed: float, t: float, neg: String, pos: String) -> void:
	var w: float = o["w"]
	var c: float = o["c"]
	var top: float = o.get("top", DOOR_H)
	for side in [-1, 1]:
		var cell := neg if side < 0 else pos
		if cell == "":
			continue
		var layer := layer_of(cell)
		var off: float = side * (t * 0.5 + 0.011)
		for e in [-1.0, 1.0]:
			var p := _wp(axis, fixed, c + e * (w * 0.5 + 0.035), top * 0.5, off)
			var size := Vector3(0.022, top, 0.07) if axis == "x" else Vector3(0.07, top, 0.022)
			box(p, size, ["trim", layer], {}, false)
		var hp := _wp(axis, fixed, c, top + 0.035, off)
		var hsize := Vector3(0.022, 0.07, w + 0.14) if axis == "x" else Vector3(w + 0.14, 0.07, 0.022)
		box(hp, hsize, ["trim", layer], {}, false)


# --- doors -------------------------------------------------------------------

func _door_leaf_mesh(width: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lw := width - 0.04
	var lh := DOOR_H - 0.05
	st.append_from(RoomKit.box_mesh(Vector3(lw, lh, 0.04), "door"), 0, Transform3D(Basis(), Vector3(0, 0, 0)))
	for z in [-0.024, 0.024]:                                  # raised panels on both faces
		st.append_from(RoomKit.box_mesh(Vector3(lw - 0.3, 0.72, 0.012), "door"), 0, Transform3D(Basis(), Vector3(0, 0.46, z)))
		st.append_from(RoomKit.box_mesh(Vector3(lw - 0.3, 0.82, 0.012), "door"), 0, Transform3D(Basis(), Vector3(0, -0.4, z)))
	st.generate_tangents()
	return st.commit()


func _make_door(o: Dictionary, axis: String, fixed: float, t: float, neg: String, pos: String) -> void:
	var w: float = o["w"]
	var c: float = o["c"]
	var layers := layer_of(neg) | layer_of(pos)
	var hinge_hi: bool = o["hinge"] == "hi"
	var hinge_at := c + (w * 0.5 if hinge_hi else -w * 0.5)
	var along := Vector3(0, 0, 1) if axis == "x" else Vector3(1, 0, 0)
	var dir := -along if hinge_hi else along                    # from the hinge across the opening
	var swing_n := _normal_vec(axis, -1 if o["swing"] == "neg" else 1)
	var positive_side := Vector3(dir.z, 0, -dir.x)             # side a positive angle swings toward
	var angle := 100.0 if swing_n.dot(positive_side) > 0.0 else -100.0

	var pivot := Node3D.new()
	pivot.position = _wp(axis, fixed, hinge_at, 0.0, 0.0)
	pivot.rotation.y = atan2(-dir.z, dir.x)
	add_child(pivot)

	var d := Door.new()
	d.open_angle = angle
	d.collision_layer = 1 | 2
	d.position = Vector3(0, DOOR_H * 0.5, 0)
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(w - 0.04, DOOR_H - 0.05, 0.08)
	shape.shape = bs
	shape.position = Vector3(w * 0.5, 0, 0)
	d.add_child(shape)
	var leaf := MeshInstance3D.new()
	leaf.mesh = _door_leaf_mesh(w)
	leaf.material_override = Mats.get_mat("door")
	leaf.layers = layers
	leaf.position = Vector3(w * 0.5, 0, 0)
	d.add_child(leaf)
	for z in [-0.034, 0.034]:                                   # lever handles, both faces
		var rose := MeshInstance3D.new()
		rose.mesh = RoomKit.box_mesh(Vector3(0.015, 0.05, 0.015), "brass")
		var lever := RoomKit.box_mesh(Vector3(0.11, 0.018, 0.016), "brass")
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.append_from(RoomKit.box_mesh(Vector3(0.05, 0.05, 0.012), "brass"), 0, Transform3D())
		st.append_from(lever, 0, Transform3D(Basis(), Vector3(-0.045, -0.015, signf(z) * 0.014)))
		st.generate_tangents()
		rose.mesh = st.commit()
		rose.material_override = Mats.get_mat("brass")
		rose.layers = layers
		rose.position = Vector3(w - 0.1, -0.06, z)
		d.add_child(rose)
	pivot.add_child(d)

	var catch_body := DoorCatch.new()
	catch_body.door = d
	catch_body.collision_layer = 2
	catch_body.collision_mask = 0
	var cshape := CollisionShape3D.new()
	var cbox := BoxShape3D.new()
	cbox.size = Vector3(w - 0.1, DOOR_H - 0.1, 0.4)
	cshape.shape = cbox
	catch_body.add_child(cshape)
	catch_body.position = Vector3(w * 0.5, DOOR_H * 0.5, 0)
	pivot.add_child(catch_body)
	doors[o["name"]] = d
	d.toggled.connect(func(_open: bool) -> void: _cull_dirty = true)
	cull_items.append(leaf)
	door_info[o["name"]] = {"center": _wp(axis, fixed, c, 0.0, 0.0), "normal": swing_n, "w": w}
	if o["open"]:
		d.set_open(true, false)


func _make_front(o: Dictionary, axis: String, fixed: float, t: float, neg: String, pos: String) -> void:
	var w: float = o["w"]
	var c: float = o["c"]
	var layer := layer_of(neg) | layer_of(pos)
	var fd := MeshInstance3D.new()
	fd.mesh = _door_leaf_mesh(w)
	fd.material_override = Mats.get_mat("door")
	fd.layers = layer
	fd.position = _wp(axis, fixed, c, DOOR_H * 0.5, 0.0)
	add_child(fd)
	cull_items.append(fd)
	var inward := -1.0 if neg != "" else 1.0                   # toward the flat
	var inside := neg if neg != "" else pos
	# Lock, peephole, and the chain, latched: nobody came in.
	var lay := layer_of(inside)
	box(_wp(axis, fixed, c - 0.28, 1.05, inward * 0.032), Vector3(0.1, 0.06, 0.02), ["brass", lay], {}, false)
	box(_wp(axis, fixed, c + 0.3, 1.6, inward * 0.025), Vector3(0.03, 0.03, 0.02), ["chrome", lay], {}, false)
	box(_wp(axis, fixed, c - 0.18, 1.62, inward * 0.032), Vector3(0.1, 0.012, 0.012), ["brass", lay], {}, false)
	box(_wp(axis, fixed, c - 0.43, 1.62, inward * 0.032), Vector3(0.04, 0.05, 0.02), ["brass", lay], {}, false)
	box(_wp(axis, fixed, c, DOOR_H * 0.5, 0.0), Vector3(w, DOOR_H, 0.08), [], {}, true)    # collision only
	front_door = _interactable("Front door", Vector3(w, DOOR_H, 0.5), _wp(axis, fixed, c, DOOR_H * 0.5, inward * 0.2))
	front_door.interacted.connect(func() -> void: said.emit("I'm not going out today."))


# --- windows -----------------------------------------------------------------

func _make_window(o: Dictionary, axis: String, fixed: float, t: float, neg: String, pos: String) -> void:
	var c: float = o["c"]
	var w: float = o["w"]
	var sill: float = o["sill"]
	var top: float = o["top"]
	var side := 1 if pos != "" else -1                          # the side that has the room
	var cell := pos if pos != "" else neg
	var layer := layer_of(cell)
	var n := _normal_vec(axis, side)                            # into the room
	var h := top - sill
	var cy := (sill + top) * 0.5
	var pane := MeshInstance3D.new()
	var quad_mesh := QuadMesh.new()
	quad_mesh.size = Vector2(w, h)
	pane.mesh = quad_mesh
	pane.material_override = _sky_mat()
	pane.layers = layer
	pane.position = _wp(axis, fixed, c, cy, -side * (t * 0.5 + 0.06))
	pane.rotation.y = atan2(n.x, n.z)
	add_child(pane)
	_panes.append(pane)
	cull_items.append(pane)

	var off := side * (t * 0.5)
	var f := ["trim", layer]
	var bar := 0.045
	var sz := func(along: float, depth: float, height: float) -> Vector3:
		return Vector3(depth, height, along) if axis == "x" else Vector3(along, height, depth)
	box(_wp(axis, fixed, c, top + bar * 0.5, off + side * 0.02), sz.call(w + 0.1, 0.05, bar), f, {}, false)        # head
	box(_wp(axis, fixed, c, sill - 0.02, off + side * 0.055), sz.call(w + 0.14, 0.11, 0.035), f, {}, false)       # sill board
	for e in [-1.0, 1.0]:
		box(_wp(axis, fixed, c + e * (w * 0.5 + 0.02), cy, off + side * 0.02), sz.call(bar, 0.05, h), f, {}, false)  # jambs
	box(_wp(axis, fixed, c, cy, off - side * 0.02), sz.call(0.035, 0.04, h), f, {}, false)                        # mullion
	box(_wp(axis, fixed, c, cy, off - side * 0.02), sz.call(w, 0.04, 0.035), f, {}, false)                        # transom
	if sill >= 0.85 and w >= 0.8:                                                                              # radiator
		box(_wp(axis, fixed, c, 0.38, off + side * 0.06), sz.call(minf(w, 1.2), 0.09, 0.5), ["white", layer], {}, false)
	if o["cur"]:
		for e in [-1.0, 1.0]:
			var cw := 0.34 if e < 0 else 0.42
			box(_wp(axis, fixed, c + e * (w * 0.5 + 0.1 + cw * 0.5 - 0.04), (top + 0.25 + sill - 0.1) * 0.5, off + side * 0.09),
				sz.call(cw, 0.07, top + 0.25 - sill + 0.1), ["curtain", layer], {}, false)
		box(_wp(axis, fixed, c, top + 0.2, off + side * 0.1), sz.call(w + 0.7, 0.03, 0.03), ["brass", layer], {}, false)


var _sky: StandardMaterial3D

func _sky_mat() -> StandardMaterial3D:
	if _sky:
		return _sky
	var grad := Gradient.new()
	grad.set_color(0, Color(0.20, 0.23, 0.28))
	grad.set_color(1, Color(0.33, 0.36, 0.40))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 8
	tex.height = 64
	_sky = StandardMaterial3D.new()
	_sky.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_sky.albedo_texture = tex
	return _sky


func set_window_light(tint: Color) -> void:
	if _sky:
		_sky.albedo_color = tint


# --- lamps and switches -----------------------------------------------------------

func _lamps_and_switches() -> void:
	for l in LAMPS:
		add_lamp(l[0], Vector3(l[1], H - 0.06, l[2]), l[3], l[4], l[5], l[6])
	for s in SWITCHES:
		var facing: Vector3 = s[3]
		var pos := Vector3(s[1], 1.25, s[2])
		var size := Vector3(0.02, 0.12, 0.08) if facing.x != 0.0 else Vector3(0.08, 0.12, 0.02)
		box(pos, size, ["trim", layer_of(s[0])], {}, false)
		var sw := _interactable("Light", Vector3(0.35, 0.35, 0.35), pos + facing * 0.1)
		var room: String = s[0]
		sw.interacted.connect(func() -> void: toggle_room(room))


## A ceiling lamp: the light, a fitting, and a glowing bulb that go on and off together.
func add_lamp(cell: String, pos: Vector3, color: Color, energy: float, range_m: float, fitting: String) -> void:
	var layer := layer_of(cell)
	var light := OmniLight3D.new()
	light.position = pos - Vector3(0, 0.05, 0)
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_m
	light.omni_attenuation = 1.3
	light.light_cull_mask = layer | L_JAMB
	light.shadow_bias = 0.04
	light.shadow_normal_bias = 1.0
	add_child(light)
	cyl(pos + Vector3(0, 0.03, 0), 0.09, 0.03, "trim", layer)                    # ceiling rose
	if fitting == "shade":
		var dome := MeshInstance3D.new()
		var m := CylinderMesh.new()
		m.top_radius = 0.07
		m.bottom_radius = 0.2
		m.height = 0.16
		m.radial_segments = 14
		dome.mesh = m
		dome.material_override = Mats.glow(Color(0.62, 0.50, 0.32))
		dome.position = pos - Vector3(0, 0.08, 0)
		dome.layers = layer
		add_child(dome)
	var bulb := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.05
	sphere.height = 0.1
	sphere.radial_segments = 10
	sphere.rings = 5
	bulb.mesh = sphere
	bulb.material_override = Mats.glow(color.lerp(Color.WHITE, 0.55))
	bulb.position = pos - Vector3(0, 0.1, 0)
	bulb.layers = layer
	add_child(bulb)
	if not lamps.has(cell):
		lamps[cell] = []
	var entry := {"light": light, "bulb": bulb, "energy": energy}
	if fitting == "shade":
		entry["shade"] = true
	(lamps[cell] as Array).append(entry)


func room_lit(room: String) -> bool:
	var arr: Array = lamps.get(room, [])
	return not arr.is_empty() and (arr[0]["light"] as Light3D).visible


func set_room_lit(room: String, on: bool) -> void:
	for l in lamps.get(room, []):
		(l["light"] as Light3D).visible = on
		(l["bulb"] as MeshInstance3D).visible = on


func toggle_room(room: String) -> void:
	set_room_lit(room, not room_lit(room))


func apply_shadows(level: int) -> void:
	for room in lamps:
		for l in lamps[room]:
			(l["light"] as Light3D).shadow_enabled = level >= 2 or (level == 1 and room.begins_with("hall"))


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


func interactable(label: String, size: Vector3, pos: Vector3) -> Interactable:
	return _interactable(label, size, pos)


## A furniture box in a room's layer.
func prop(cell: String, center: Vector3, size: Vector3, mat: String, yaw := 0.0, collide := true) -> void:
	box(center, size, [mat, layer_of(cell)], {}, collide, yaw)


## A soft dark blotch (water stain, grime) lying on a wall, ceiling or floor.
func stain(cell: String, center: Vector3, normal: Vector3, size: float, aspect := 1.0) -> void:
	var up := Vector3.UP if absf(normal.y) < 0.9 else Vector3.RIGHT
	quad(center, normal, up, size, size * aspect, "_stain", layer_of(cell))


## A soft shadow under a piece of furniture (fake occlusion).
func blob_shadow(cell: String, center: Vector3, w: float, d: float) -> void:
	quad(Vector3(center.x, 0.004, center.z), Vector3.UP, Vector3.BACK, w, d, "_stain", layer_of(cell))


# --- for the world, look-dev and tests -------------------------------------------------

func spawn_point() -> Vector3:
	return Vector3(-0.3, 0.05, -0.75)


func spawn_yaw() -> float:
	return 0.0                                          # facing north, toward the hall door


func _spot(pos: Vector3, target: Vector3) -> Array:
	var d := target - pos
	var eye := Vector3(pos.x, pos.y + Player.EYE_HEIGHT, pos.z)
	d = target - eye
	return [pos, atan2(-d.x, -d.z), atan2(d.y, Vector2(d.x, d.z).length())]


## Named viewpoints for look-dev and tests: name -> [position, yaw, pitch].
func debug_spots() -> Dictionary:
	return {
		"door": _spot(Vector3(-0.3, 0.05, -0.75), Vector3(-0.3, 1.5, -4.6)),
		"hall": _spot(Vector3(-0.3, 0.05, -5.2), Vector3(-0.3, 1.2, -10.0)),
		"bathdoor": _spot(Vector3(-0.3, 0.05, -2.2), Vector3(-1.0, 1.1, -1.2)),
		"phone": _spot(Vector3(-0.3, 0.05, -8.3), Vector3(-0.3, 0.9, -10.0)),
		"end": _spot(Vector3(-0.3, 0.05, -8.9), Vector3(-0.3, 1.4, -0.0)),
		"hallw": _spot(Vector3(-1.7, 0.05, -6.7), Vector3(-6.6, 1.3, -6.7)),
		"bedroom": _spot(Vector3(-3.9, 0.05, -3.3), Vector3(-5.3, 0.6, -3.9)),
		"dressing": _spot(Vector3(-4.5, 0.05, -1.8), Vector3(-5.8, 1.0, -0.4)),
		"bath": _spot(Vector3(-1.5, 0.05, -0.45), Vector3(-3.0, 0.7, -2.0)),
		"dads": _spot(Vector3(-1.5, 0.05, -5.5), Vector3(-3.0, 0.7, -3.4)),
		"spare": _spot(Vector3(-5.0, 0.05, -7.85), Vector3(-5.8, 0.6, -9.4)),
		"utility": _spot(Vector3(-1.5, 0.05, -7.9), Vector3(-2.6, 0.8, -9.6)),
		"kitchen": _spot(Vector3(1.2, 0.05, -2.5), Vector3(3.4, 0.9, -0.4)),
		"living": _spot(Vector3(1.4, 0.05, -7.0), Vector3(3.2, 0.6, -4.0)),
		"box": _spot(Vector3(1.2, 0.05, -9.0), Vector3(2.2, 0.9, -9.6)),
		"study": _spot(Vector3(3.9, 0.05, -8.5), Vector3(3.0, 0.8, -9.6)),
	}


func set_ceilings_visible(on: bool) -> void:
	ceilings.visible = on


# --- drawing only what can be seen ---------------------------------------------------------
# Each room's meshes live on that room's layer. The player's room, and the rooms reachable
# through openings that are open (arches always, doors when open), up to two steps away, are
# drawn; the rest are hidden. This replaces occlusion culling, which the web build cannot afford.

func _process(_delta: float) -> void:
	if viewer == null:
		return
	var cell := cell_at(viewer.global_position)
	if cell != "" and (cell != _cull_cell or _cull_dirty):
		_cull_cell = cell
		_cull_dirty = false
		_refresh_cull()


func visible_cells(from: String, depth := 2) -> Array:
	var seen := [from]
	var frontier := [from]
	for _i in depth:
		var next := []
		for c in frontier:
			for l in _links:
				var other := ""
				if l[0] == c:
					other = l[1]
				elif l[1] == c:
					other = l[0]
				if other == "" or other in seen:
					continue
				var is_open: bool = l[2] == "" or (doors.has(l[2]) and (doors[l[2]] as Door).is_open)
				if is_open:
					seen.append(other)
					next.append(other)
		frontier = next
	return seen


func _refresh_cull() -> void:
	var mask := L_JAMB
	for c in visible_cells(_cull_cell):
		mask |= layer_of(c)
	for n in cull_items:
		n.visible = (n.layers & mask) != 0


func show_everything() -> void:
	viewer = null
	for n in cull_items:
		n.visible = true
