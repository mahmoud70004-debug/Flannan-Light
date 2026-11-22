class_name Apartment
extends RoomKit
## Martin's flat. A T-shaped hall (front hall, a door, the long back hall, a west leg) with
## thirteen rooms off it, so nothing shows the whole flat at once. Everything is built from
## data in code: cells (rooms) on a grid, walls derived from where cells touch, and a list of
## openings (doors, arches, windows). +X east, -Z north, y up, floor at y = 0. The front door
## is on the south side; the landline stands at the far north end of the back hall.

signal said(text: String)             ## a line of Martin's inner voice for the HUD
signal used(id: String)               ## the player used a prop registered with use_point()

const H := 2.5
const DOOR_H := 2.05
const DOOR_W := 0.9                   ## clear opening of every interior door
const T_IN := 0.12
const T_EXT := 0.22
const X_W := -6.6
const X_E := 5.0
const Z_S := 0.0
const Z_N := -10.0

const L_ENTRY := 1 << 1
const L_KIT := 1 << 2
const L_LIV := 1 << 3
const L_HALL := 1 << 4
const L_BATH := 1 << 5
const L_STOR := 1 << 6
const L_BED1 := 1 << 7
const L_BED2 := 1 << 8
const L_JAMB := 1 << 12              ## door/window reveals: lit by every lamp, since two rooms see them

## cell -> {r: [x0, x1, z0, z1] on the wall centre lines (z0 is the north edge), floor, wall, layer}
const CELLS := {
	"entry": {"r": [-1.0, 1.2, -2.2, 0.0], "floor": "floor_hall", "wall": "wall", "layer": L_ENTRY},
	"kitchen": {"r": [1.2, 5.0, -2.2, 0.0], "floor": "tile", "wall": "wall", "layer": L_KIT},
	"living": {"r": [-1.0, 5.0, -9.6, -2.2], "floor": "floor_wood", "wall": "wall", "layer": L_LIV},
	"hall": {"r": [-6.4, -1.0, -5.6, -4.2], "floor": "floor_hall", "wall": "wall", "layer": L_HALL},
	"bath": {"r": [-6.4, -3.8, -4.2, -1.6], "floor": "tile", "wall": "wall_damp", "layer": L_BATH},
	"storage": {"r": [-3.8, -1.0, -4.2, -1.6], "floor": "floor_hall", "wall": "wall", "layer": L_STOR},
	"bed1": {"r": [-6.4, -3.4, -9.6, -5.6], "floor": "floor_wood", "wall": "wall", "layer": L_BED1},
	"bed2": {"r": [-3.4, -1.0, -9.6, -5.6], "floor": "floor_wood", "wall": "wall", "layer": L_BED2},
}

## Openings. axis "x": a wall running along Z at x = fixed; "z": along X at z = fixed. c is the
## centre along the wall. Doors: hinge "lo"/"hi" end, swing "neg"/"pos" side, open at start.
const OPENINGS := [
	{"kind": "front", "axis": "z", "fixed": 0.0, "c": 0.1, "w": 0.95},
	{"kind": "arch", "axis": "x", "fixed": 1.2, "c": -1.1, "w": 1.0},
	{"kind": "arch", "axis": "z", "fixed": -2.2, "c": 0.1, "w": 1.4},
	{"kind": "arch", "axis": "z", "fixed": -2.2, "c": 3.6, "w": 1.6},
	{"kind": "arch", "axis": "x", "fixed": -1.0, "c": -4.9, "w": 1.2},
	{"kind": "door", "name": "bath", "axis": "z", "fixed": -4.2, "c": -5.1, "w": 0.9, "hinge": "lo", "swing": "pos", "open": false},
	{"kind": "door", "name": "storage", "axis": "z", "fixed": -4.2, "c": -2.4, "w": 0.9, "hinge": "hi", "swing": "pos", "open": false},
	{"kind": "door", "name": "bed1", "axis": "z", "fixed": -5.6, "c": -4.9, "w": 0.9, "hinge": "lo", "swing": "neg", "open": false},
	{"kind": "door", "name": "bed2", "axis": "z", "fixed": -5.6, "c": -2.2, "w": 0.9, "hinge": "hi", "swing": "neg", "open": false},
	# Windows: sill and top heights, curtains optional.
	{"kind": "window", "axis": "x", "fixed": 5.0, "c": -5.6, "w": 1.8, "sill": 0.9, "top": 2.05, "cur": true},
	{"kind": "window", "axis": "x", "fixed": 5.0, "c": -8.4, "w": 1.2, "sill": 0.9, "top": 2.05, "cur": true},
	{"kind": "window", "axis": "z", "fixed": -9.6, "c": 1.0, "w": 1.4, "sill": 0.9, "top": 2.05, "cur": true},
	{"kind": "window", "axis": "z", "fixed": -9.6, "c": 3.4, "w": 1.4, "sill": 0.9, "top": 2.05, "cur": true},
	{"kind": "window", "axis": "x", "fixed": 5.0, "c": -1.1, "w": 1.0, "sill": 0.95, "top": 2.05, "cur": false},
	{"kind": "window", "axis": "z", "fixed": 0.0, "c": 3.0, "w": 1.2, "sill": 1.0, "top": 2.05, "cur": false},
	{"kind": "window", "axis": "z", "fixed": -9.6, "c": -4.85, "w": 1.0, "sill": 1.0, "top": 2.0, "cur": true},
	{"kind": "window", "axis": "z", "fixed": -9.6, "c": -2.2, "w": 1.0, "sill": 1.0, "top": 2.0, "cur": true},
	{"kind": "window", "axis": "x", "fixed": -6.4, "c": -2.9, "w": 0.6, "sill": 1.5, "top": 2.05, "cur": false},
	{"kind": "window", "axis": "z", "fixed": -1.6, "c": -2.4, "w": 0.7, "sill": 1.4, "top": 2.0, "cur": false},
	{"kind": "window", "axis": "x", "fixed": -6.4, "c": -4.9, "w": 0.8, "sill": 1.0, "top": 2.0, "cur": false},
]

## Ceiling lamps: [cell, x, z, colour, energy, range, fitting]  (fitting: "bulb", "shade")
const LAMPS := [
	["entry", 0.1, -1.1, Color(1.0, 0.80, 0.55), 0.9, 4.0, "bulb"],
	["kitchen", 3.0, -1.1, Color(0.92, 0.97, 0.88), 0.95, 4.6, "bulb"],
	["living", 1.2, -4.8, Color(1.0, 0.8, 0.58), 1.0, 6.0, "shade"],
	["living", 3.6, -8.2, Color(1.0, 0.76, 0.52), 0.7, 5.0, "bulb"],
	["hall", -2.2, -4.9, Color(1.0, 0.78, 0.52), 0.8, 4.4, "shade"],
	["hall", -5.2, -4.9, Color(1.0, 0.76, 0.5), 0.6, 3.6, "bulb"],
	["bath", -5.0, -2.9, Color(0.86, 0.93, 1.0), 1.0, 3.6, "bulb"],
	["storage", -2.4, -2.9, Color(1.0, 0.74, 0.5), 0.8, 3.8, "bulb"],
	["bed1", -4.85, -7.6, Color(1.0, 0.78, 0.55), 0.9, 4.2, "shade"],
	["bed2", -2.2, -7.6, Color(1.0, 0.78, 0.55), 0.8, 4.0, "shade"],
]

## Light switches: [cell, x, z, facing (direction the plate looks, into the room)]
const SWITCHES := [
	["entry", -0.93, -0.55, Vector3(1, 0, 0)],
	["kitchen", 1.27, -1.9, Vector3(1, 0, 0)],
	["living", -0.93, -3.4, Vector3(1, 0, 0)],
	["hall", -3.6, -5.53, Vector3(0, 0, 1)],
	["bath", -4.3, -4.13, Vector3(0, 0, 1)],
	["storage", -1.6, -4.13, Vector3(0, 0, 1)],
	["bed1", -3.9, -5.67, Vector3(0, 0, -1)],
	["bed2", -1.5, -5.67, Vector3(0, 0, -1)],
]

var switch_halo := {}                  ## room -> the glow around its light switch (shown while the room is dark)
var switch_at := {}                    ## room -> where its light switch is
var hang_errors: Array = []            ## wall items that would have sat on a door, arch or window (the test wants none)
var doors := {}                        ## name -> Door
var door_info := {}                    ## name -> {center, normal (toward the swing side), w}
var lamps := {}                        ## cell -> Array of {light, bulb}
var front_door: Interactable
var use_points := {}                   ## id -> Interactable (props the game logic cares about)
var pois := {}                         ## id -> floor position, for reachability tests
var swarms: Array = []                 ## Flies nodes
var movables := {}                     ## id -> Node3D that the story can show, hide or move
var stranger_spots: Array = []         ## floor positions where the stranger may stand
var _tv: MeshInstance3D
var _tv_mat: StandardMaterial3D
var _tv_light: OmniLight3D
var phone: Interactable
var _panes: Array[MeshInstance3D] = []
var _lines := {}                       ## wall line key -> side records (wall generation)
var _ext := {}                         ## cell -> {w,e,n,s: true} for sides with outside behind them
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


## Interior bounds [x0, x1, z0, z1] of a cell: the cell minus half the walls around it
## (outside walls are thicker; a side counts as outside if any part of it has no room behind).
func ib(cell: String) -> Array:
	var r: Array = CELLS[cell]["r"]
	var e: Dictionary = _ext.get(cell, {})
	return [
		r[0] + (T_EXT if e.get("w", false) else T_IN) * 0.5,
		r[1] - (T_EXT if e.get("e", false) else T_IN) * 0.5,
		r[2] + (T_EXT if e.get("n", false) else T_IN) * 0.5,
		r[3] - (T_EXT if e.get("s", false) else T_IN) * 0.5]


## The whole building's bounds [x0, x1, z0, z1].
func footprint() -> Array:
	var b := [INF, -INF, INF, -INF]
	for name in CELLS:
		var r: Array = CELLS[name]["r"]
		b = [minf(b[0], r[0]), maxf(b[1], r[1]), minf(b[2], r[2]), maxf(b[3], r[3])]
	return b


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
	var f := footprint()
	for y in [-0.2, H + 0.2]:
		var shape := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(f[1] - f[0] + 1.0, 0.4, f[3] - f[2] + 1.0)
		shape.shape = bs
		shape.position = Vector3((f[0] + f[1]) * 0.5, y, (f[2] + f[3]) * 0.5)
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
			if neg == "" or pos == "":
				var c := pos if neg == "" else neg
				var side_name := ""
				if line["axis"] == "x":
					side_name = "w" if neg == "" else "e"
				else:
					side_name = "n" if neg == "" else "s"
				if not _ext.has(c):
					_ext[c] = {}
				_ext[c][side_name] = true
			_wall_run(line["axis"], line["fixed"], b0, b1, t, ops, neg, pos)


func _wall_run(axis: String, fixed: float, a0: float, a1: float, t: float, ops: Array, neg: String, pos: String) -> void:
	var neg_spec := _spec(neg)
	var pos_spec := _spec(pos)
	# Painted reveals: lit by every lamp, but each room's are their own mesh so a mesh only meets nearby lights
	var edge: Array = [] if (neg_spec.is_empty() and pos_spec.is_empty()) else ["trim", L_JAMB, neg if neg != "" else pos]
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


## Wall items (pictures, switches, hooks) must not sit on a door, an arch or a window: a door swings away and
## leaves them hanging in the air. `axis` is the wall's axis (a wall at constant x has axis "x").
func hang_ok(item: String, pos: Vector3, axis: String, half: float, y0: float, y1: float) -> bool:
	var fixed := pos.x if axis == "x" else pos.z
	var along := pos.z if axis == "x" else pos.x
	for o in OPENINGS:
		if o["axis"] != axis or absf(float(o["fixed"]) - fixed) > 0.4:
			continue
		if absf(float(o["c"]) - along) >= float(o["w"]) * 0.5 + half + 0.05:
			continue
		var lo: float = o.get("sill", 0.0)
		var hi: float = o.get("top", DOOR_H)
		if y1 > lo and y0 < hi:
			hang_errors.append("%s overlaps the %s at %s" % [item, o["kind"], o["c"]])
			return false
	return true


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
	front_door = use_point("front_door", "Front door", Vector3(w, DOOR_H, 0.5), _wp(axis, fixed, c, DOOR_H * 0.5, inward * 0.2))


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
	pane.material_override = _sky_mat(not o["cur"])
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
	var yaw_in := atan2(-n.x, -n.z)                                                                            # turns a model's front (-Z) into the room
	if sill >= 0.85 and w >= 0.8:                                                                              # radiator under the window
		var rw := minf(w, 1.2)
		if not model("radiator", _wp(axis, fixed, c, 0.08, off + side * 0.06), Basis(Vector3.UP, yaw_in) * Basis.from_scale(Vector3(rw, 1.0, 1.0)), layer):
			box(_wp(axis, fixed, c, 0.38, off + side * 0.06), sz.call(rw, 0.09, 0.5), ["white", layer], {}, false)
	if o["cur"]:                                                # drawn across the window, with a gap in the middle
		var gap := maxf(w * 0.14, 0.14)
		var cw := (w + 0.12 - gap) * 0.5
		var ch := top + 0.25 - sill + 0.1
		for e in [-1.0, 1.0]:
			var cp := _wp(axis, fixed, c + e * (w * 0.5 + 0.06 - cw * 0.5), sill - 0.1, off + side * 0.08)
			if not model("curtain", cp, Basis(Vector3.UP, yaw_in) * Basis.from_scale(Vector3(cw, ch, 1.0)), layer):
				box(_wp(axis, fixed, c + e * (w * 0.5 + 0.06 - cw * 0.5), (top + 0.25 + sill - 0.1) * 0.5, off + side * 0.09),
					sz.call(cw, 0.07, ch), ["curtain", layer], {}, false)
		box(_wp(axis, fixed, c, top + 0.2, off + side * 0.1), sz.call(w + 0.7, 0.03, 0.03), ["brass", layer], {}, false)


var _sky_mats := {}                   ## "curtain" / "blind" -> the material of the view
var _skyline := {}
var _sky_figure := false
var _sky_tint := Color(1, 1, 1)


## The view from every window: a wet, dark night. Street lamps glow orange through the haze, two rows of
## buildings with a few lit windows, rain streaks and droplets on dirty glass. Windows without curtains get a
## venetian blind drawn over the top half. From day 6 a lit window across the street has someone standing in it
## (at the middle of the pane, where the curtains leave their gap).
func _sky_texture(with_figure: bool, blind: bool) -> ImageTexture:
	var key := "%s%s" % [with_figure, blind]
	if _skyline.has(key):
		return _skyline[key]
	var w := 256
	var h := 128
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for y in h:
		var t := float(y) / float(h - 1)
		var c := Color(0.018, 0.022, 0.04).lerp(Color(0.16, 0.115, 0.09), pow(t, 1.9))
		for x in w:
			img.set_pixel(x, y, c)
	_glow(img, 44, 104, 36, 0.5)
	_glow(img, 150, 112, 44, 0.45)
	_glow(img, 226, 98, 28, 0.4)
	_buildings(img, rng, 28, 70, Color(0.05, 0.055, 0.075), 0.0, with_figure)
	_buildings(img, rng, 40, 96, Color(0.012, 0.013, 0.02), 0.11, with_figure)
	if with_figure:                                     # a lit window, and a dark shape standing in it
		var fx := 124
		var fy := 52
		for dy in 15:
			for dx in 12:
				img.set_pixel(fx + dx, fy + dy, Color(0.85, 0.68, 0.36))
		for dy in range(3, 15):
			for dx in range(4, 8):
				img.set_pixel(fx + dx, fy + dy, Color(0.025, 0.025, 0.03))
		for dy in range(1, 6):
			for dx in range(4, 8):
				img.set_pixel(fx + dx, fy + dy, Color(0.025, 0.025, 0.03))
	for i in 110:                                       # rain streaks
		var sx := rng.randi_range(0, w - 1)
		var sy := rng.randi_range(0, h - 24)
		var len := rng.randi_range(7, 22)
		var a := rng.randf_range(0.07, 0.2)
		for k in len:
			var px := sx + int(float(k) * 0.12)
			if px < w and sy + k < h:
				img.set_pixel(px, sy + k, img.get_pixel(px, sy + k) + Color(0.5, 0.56, 0.66) * a)
	for i in 16:                                        # droplets on the glass
		var dx := rng.randi_range(2, w - 3)
		var dy := rng.randi_range(2, h - 8)
		img.set_pixel(dx, dy, img.get_pixel(dx, dy) + Color(0.35, 0.33, 0.3))
		img.set_pixel(dx, dy + 1, img.get_pixel(dx, dy + 1) * 0.55)
	if blind:                                           # the top of the window is behind a slatted blind
		for y in int(float(h) * 0.64):
			if y % 8 < 6:
				for x in w:
					var shade := 0.14 + 0.05 * sin(float(x) * 0.07 + float(y))
					img.set_pixel(x, y, img.get_pixel(x, y) * 0.12 + Color(shade * 1.1, shade, shade * 0.9))
	for y in h:                                         # dirt thickens toward the edges and the sill
		for x in w:
			var u := absf(float(x) / float(w - 1) - 0.5) * 2.0
			var v := float(y) / float(h - 1)
			var dirt := 1.0 - 0.5 * pow(maxf(u, absf(v - 0.5) * 2.0), 3.0) - 0.18 * pow(v, 6.0)
			img.set_pixel(x, y, img.get_pixel(x, y) * dirt)
	var tex := ImageTexture.create_from_image(img)
	_skyline[key] = tex
	return tex


func _glow(img: Image, cx: int, cy: int, r: int, strength: float) -> void:
	for y in range(maxi(cy - r, 0), mini(cy + r, img.get_height())):
		for x in range(maxi(cx - r, 0), mini(cx + r, img.get_width())):
			var d := Vector2(float(x - cx), float(y - cy) * 1.3).length() / float(r)
			if d < 1.0:
				img.set_pixel(x, y, img.get_pixel(x, y) + Color(0.95, 0.55, 0.2) * (pow(1.0 - d, 2.0) * strength))


## One row of buildings along the bottom of the view. `lit`: the chance that a window has a light on.
func _buildings(img: Image, rng: RandomNumberGenerator, min_h: int, max_h: int, base: Color, lit: float, keep_gap: bool) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var x := -4
	while x < w:
		var bw := rng.randi_range(18, 40)
		var bh := rng.randi_range(min_h, max_h)
		var shade := rng.randf_range(0.85, 1.15)
		for yy in range(h - bh, h):
			for xx in range(maxi(x, 0), mini(x + bw - 1, w)):
				img.set_pixel(xx, yy, base * shade)
		if lit > 0.0:
			for wy in range(h - bh + 6, h - 4, 9):
				for wx in range(x + 4, x + bw - 6, 7):
					if rng.randf() < lit and (wx < 112 or wx > 148):
						var cold := rng.randf() < 0.25
						var wc := Color(0.3, 0.42, 0.62) if cold else Color(0.78, 0.58, 0.28)
						for dy in 4:
							for dx in 4:
								if wx + dx < w and wy + dy < h:
									img.set_pixel(wx + dx, wy + dy, wc * rng.randf_range(0.7, 1.0))
		x += bw
	if lit > 0.0:                                       # the building that holds the figure's window
		for yy in range(h - 88, h):
			for xx in range(106, 150):
				img.set_pixel(xx, yy, Color(0.012, 0.013, 0.02))


func _sky_mat(blind: bool) -> StandardMaterial3D:
	var k := "blind" if blind else "curtain"
	if _sky_mats.has(k):
		return _sky_mats[k]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = _sky_texture(_sky_figure, blind)
	m.albedo_color = _sky_tint
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	_sky_mats[k] = m
	return m


func set_skyline(figure: bool) -> void:
	_sky_figure = figure
	for k in _sky_mats:
		(_sky_mats[k] as StandardMaterial3D).albedo_texture = _sky_texture(figure, k == "blind")


func set_window_light(tint: Color) -> void:
	_sky_tint = tint
	for k in _sky_mats:
		(_sky_mats[k] as StandardMaterial3D).albedo_color = tint


# --- lamps and switches -----------------------------------------------------------

func _lamps_and_switches() -> void:
	for l in LAMPS:
		add_lamp(l[0], Vector3(l[1], H - 0.06, l[2]), l[3], l[4], l[5], l[6])
	for s in SWITCHES:
		var facing: Vector3 = s[3]
		var pos := Vector3(s[1], 1.25, s[2])
		var size := Vector3(0.02, 0.12, 0.08) if facing.x != 0.0 else Vector3(0.08, 0.12, 0.02)
		hang_ok("light switch in %s" % s[0], pos, "x" if facing.x != 0.0 else "z", 0.06, 1.19, 1.31)
		box(pos, size, ["trim", layer_of(s[0])], {}, false)
		var sw := _interactable("Light switch", Vector3(0.5, 0.6, 0.5), pos + facing * 0.15)
		var room: String = s[0]
		_switch_glow(room, pos, facing)
		switch_at[room] = pos
		sw.interacted.connect(func() -> void:
			var sfx := get_node_or_null("/root/Sfx")                # (looked up at run time: tests compile this class without autoloads)
			if sfx:
				sfx.call("play_at", "switch", pos, -2.0, 8.0, 2.0)
			toggle_room(room))


## A switch you can find in the dark: a small amber pilot light on the plate (always on) and a soft halo around it
## that shows while the room is dark. Both are unshaded, so no room lighting changes them.
func _switch_glow(room: String, pos: Vector3, facing: Vector3) -> void:
	var layer := layer_of(room)
	var yaw := atan2(facing.x, facing.z)
	var pilot := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.028, 0.04)
	pilot.mesh = q
	pilot.material_override = _glow_mat(false)
	pilot.layers = layer
	pilot.position = pos + facing * 0.013
	pilot.rotation.y = yaw
	add_child(pilot)
	cull_items.append(pilot)
	var halo := MeshInstance3D.new()
	var hq := QuadMesh.new()
	hq.size = Vector2(0.42, 0.42)
	halo.mesh = hq
	halo.material_override = _glow_mat(true)
	halo.layers = layer
	halo.position = pos + facing * 0.016
	halo.rotation.y = yaw
	halo.visible = not room_lit(room)
	add_child(halo)                                       # not in cull_items: its visibility belongs to the room's lamps
	switch_halo[room] = halo


var _glow_mats := {}


func _glow_mat(halo: bool) -> StandardMaterial3D:
	if _glow_mats.has(halo):
		return _glow_mats[halo]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.72, 0.32)
	if halo:
		var g := Gradient.new()
		g.colors = PackedColorArray([Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.0)])
		g.offsets = PackedFloat32Array([0.0, 1.0])
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 64
		t.height = 64
		m.albedo_texture = t
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.no_depth_test = false
	_glow_mats[halo] = m
	return m


## A ceiling lamp: the light, a fitting, and a glowing bulb that go on and off together.
func add_lamp(cell: String, pos: Vector3, color: Color, energy: float, range_m: float, fitting: String) -> void:
	var layer := layer_of(cell)
	var shade_node: MeshInstance3D = null
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
		shade_node = dome
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
	if shade_node:
		entry["shade"] = shade_node
	(lamps[cell] as Array).append(entry)


func room_lit(room: String) -> bool:
	var arr: Array = lamps.get(room, [])
	return not arr.is_empty() and (arr[0]["light"] as Light3D).visible


func set_room_lit(room: String, on: bool) -> void:
	for l in lamps.get(room, []):
		(l["light"] as Light3D).visible = on
		(l["bulb"] as MeshInstance3D).visible = on
		if l.has("shade"):
			(l["shade"] as MeshInstance3D).visible = on
	if switch_halo.has(room):
		(switch_halo[room] as MeshInstance3D).visible = not on


func toggle_room(room: String) -> void:
	set_room_lit(room, not room_lit(room))


## Lamps waver a little more the higher the fear is (called every frame by the world).
func update_flicker(fear: float, t: float) -> void:
	if fear < 0.15:
		return
	var i := 0
	for room in lamps:
		for l in lamps[room]:
			var light: Light3D = l["light"]
			if light.visible:
				var w := sin(t * 13.0 + float(i) * 1.7) * sin(t * 7.3 + float(i) * 2.9)
				light.light_energy = float(l["energy"]) * (1.0 + fear * 0.2 * w - (0.0 if fear < 0.6 or w < 0.7 else fear * 0.25))
			i += 1


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


## A prop the game logic reacts to: using it emits `used(id)`. Can be switched off/on and relabelled.
func use_point(id: String, label: String, size: Vector3, pos: Vector3) -> Interactable:
	var it := _interactable(label, size, pos)
	it.set_meta("id", id)
	it.interacted.connect(func() -> void: used.emit(id))
	use_points[id] = it
	pois[id] = Vector3(pos.x, 0.0, pos.z)
	return it


func set_use(id: String, enabled: bool, label := "") -> void:
	if not use_points.has(id):
		return
	var it: Interactable = use_points[id]
	it.collision_layer = 2 if enabled else 0
	if label != "":
		it.prompt = label


## A fly swarm over something rotten.
func add_flies(cell: String, pos: Vector3, count := 14, radius := 0.28) -> Flies:
	var f := Flies.make(self, layer_of(cell), pos, count, radius)
	swarms.append(f)
	cull_items.append(f.get_meta("mesh"))
	return f


## A furniture box in a room's layer.
func prop(cell: String, center: Vector3, size: Vector3, mat: String, yaw := 0.0, collide := true) -> void:
	box(center, size, [mat, layer_of(cell)], {}, collide, yaw)


## A Blender model in a room's layer; `yaw` turns it, `extra` is any further rotation (a bottle on its side).
func place_model(model_name: String, cell: String, pos: Vector3, yaw := 0.0, extra := Basis.IDENTITY, scale := Vector3.ONE) -> bool:
	return model(model_name, pos, Basis(Vector3.UP, yaw) * extra * Basis.from_scale(scale), layer_of(cell))


## A soft dark blotch (water stain, grime) lying on a wall, ceiling or floor.
func stain(cell: String, center: Vector3, normal: Vector3, size: float, aspect := 1.0) -> void:
	var up := Vector3.UP if absf(normal.y) < 0.9 else Vector3.RIGHT
	quad(center, normal, up, size, size * aspect, "_stain", layer_of(cell))


## A soft shadow under a piece of furniture (fake occlusion).
func blob_shadow(cell: String, center: Vector3, w: float, d: float) -> void:
	quad(Vector3(center.x, 0.004, center.z), Vector3.UP, Vector3.BACK, w, d, "_stain", layer_of(cell))


# --- things the story moves, a TV that wakes up, the epilogue ------------------------------------

## A small object made of separate meshes, so the story can hide or move it.
## parts: [[offset, size, material key, optional "sphere"]]
func make_movable(id: String, cell: String, pos: Vector3, parts: Array, yaw := 0.0, shown := true) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = yaw
	add_child(n)
	for p in parts:
		var mi := MeshInstance3D.new()
		if p.size() > 3 and p[3] == "sphere":
			var sm := SphereMesh.new()
			sm.radius = (p[1] as Vector3).x
			sm.height = (p[1] as Vector3).x * 2.0
			sm.radial_segments = 12
			sm.rings = 6
			mi.mesh = sm
		else:
			mi.mesh = RoomKit.box_mesh(p[1], p[2])
		mi.material_override = Mats.get_mat(p[2])
		mi.position = p[0]
		mi.layers = layer_of(cell) | L_JAMB
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(mi)
		cull_items.append(mi)
	n.visible = shown
	movables[id] = n
	return n


func set_movable_visible(id: String, on: bool) -> void:
	if movables.has(id):
		(movables[id] as Node3D).visible = on


func setup_tv(pos: Vector3, w: float, h: float) -> void:
	var img := Image.create(96, 54, false, Image.FORMAT_L8)
	for y in 54:
		for x in 96:
			var v := randf()
			img.set_pixel(x, y, Color(v, v, v))
	_tv_mat = StandardMaterial3D.new()
	_tv_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_tv_mat.albedo_texture = ImageTexture.create_from_image(img)
	_tv_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_tv_mat.texture_repeat = true
	_tv = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(w, h)
	_tv.mesh = q
	_tv.material_override = _tv_mat
	_tv.position = pos
	_tv.layers = L_LIV
	_tv.visible = false
	add_child(_tv)                                     # not culled by room: it is shown only when the story says so
	_tv_light = OmniLight3D.new()                      # the cold light of a TV nobody is watching
	_tv_light.position = pos + Vector3(0, 0.1, 0.5)
	_tv_light.light_color = Color(0.7, 0.8, 1.0)
	_tv_light.light_energy = 0.0
	_tv_light.omni_range = 5.5
	_tv_light.omni_attenuation = 1.2
	_tv_light.light_cull_mask = L_LIV | L_JAMB
	add_child(_tv_light)


func tv_position() -> Vector3:
	return _tv.position if _tv else Vector3(1.0, 1.0, -9.2)


func set_tv(on: bool) -> void:
	if _tv:
		_tv.visible = on
	if _tv_light:
		_tv_light.light_energy = 0.9 if on else 0.0


func set_tv_level(v: float) -> void:
	if _tv_mat:
		_tv_mat.albedo_color = Color(v, v, v * 1.05)
		_tv_mat.uv1_offset = Vector3(randf(), randf(), 0.0)
	if _tv_light and _tv.visible:
		_tv_light.light_energy = 0.4 + v * 0.8


## Forty-one days later: the lamps are off but one, the windows are bright, and he is on the sofa.
func show_epilogue() -> void:
	for c in lamps:
		set_room_lit(c, c == "living_floor")
	set_window_light(Color(0.55, 0.6, 0.66))
	set_movable_visible("body", true)
	set_tv(true)
	set_tv_level(0.5)
	for f in swarms:
		(f as Flies).intensity = 1.0
	add_flies("living", Vector3(1.0, 1.2, -6.4), 26, 0.5).intensity = 1.0
	add_flies("living", Vector3(1.0, 0.9, -6.7), 22, 0.35).intensity = 1.0


# --- for the world, look-dev and tests -------------------------------------------------

func spawn_point() -> Vector3:
	return Vector3(0.1, 0.05, -0.75)


## Where Martin wakes up each morning: beside the bed, looking into the room.
func wake_point() -> Vector3:
	return Vector3(-4.55, 0.05, -6.25)


func wake_yaw() -> float:
	return 0.3


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
		"door": _spot(Vector3(0.1, 0.05, -0.75), Vector3(0.1, 1.3, -5.0)),
		"living": _spot(Vector3(0.1, 0.05, -2.9), Vector3(2.5, 0.7, -7.0)),
		"dining": _spot(Vector3(1.8, 0.05, -4.0), Vector3(3.9, 0.8, -5.6)),
		"sofa": _spot(Vector3(0.0, 0.05, -3.3), Vector3(1.0, 0.9, -6.4)),
		"tv": _spot(Vector3(3.6, 0.05, -3.7), Vector3(1.0, 0.6, -9.0)),
		"kitchen": _spot(Vector3(2.2, 0.05, -1.0), Vector3(4.6, 0.5, -1.9)),
		"trash": _spot(Vector3(3.5, 0.05, -1.0), Vector3(4.7, 0.3, -1.9)),
		"hall": _spot(Vector3(-1.3, 0.05, -4.9), Vector3(-6.0, 1.0, -4.9)),
		"phone": _spot(Vector3(-4.6, 0.05, -4.9), Vector3(-6.0, 0.8, -4.9)),
		"bed1": _spot(Vector3(-4.5, 0.05, -6.2), Vector3(-4.85, 0.6, -8.4)),
		"bed2": _spot(Vector3(-2.0, 0.05, -6.3), Vector3(-1.6, 0.6, -8.4)),
		"bath": _spot(Vector3(-5.1, 0.05, -3.7), Vector3(-5.4, 0.8, -2.0)),
		"switch": _spot(Vector3(-1.7, 0.05, -6.9), Vector3(-1.5, 1.25, -5.67)),
		"storage": _spot(Vector3(-2.4, 0.05, -3.6), Vector3(-2.4, 0.6, -1.9)),
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
