class_name Apartment
extends RoomKit
## Martin's flat: a long, narrow corridor with the rooms leading off it.
## Everything is built from boxes in code. Coordinates: +X east, -Z north (down the
## corridor), y up, floor at y = 0. The front door is at the south end (z = 0); the
## landline stands at the far north end, so every call means walking the whole corridor.
##
##   z=0   [front door]
##         bath | corridor | kitchen + living room
##         bed  |          |
##         dad's|          | closet
##   z=-10.6      [phone, window]

signal said(text: String)             ## a line of Martin's inner voice for the HUD

const H := 2.55
const T := 0.12
const DOOR_H := 2.1

const L_CORR := 1 << 1
const L_BATH := 1 << 2
const L_BED := 1 << 3
const L_LIVING := 1 << 4
const L_STORAGE := 1 << 5
const L_CLOSET := 1 << 6
const L_OUTSIDE := 1 << 7

## name -> [x0, x1, z0, z1, floor material, wall material, layer]
const ROOMS := {
	"corridor": [-0.65, 0.65, -10.6, 0.0, "floor_hall", "wall", L_CORR],
	"bath": [-3.37, -0.77, -2.4, 0.0, "tile", "wall_damp", L_BATH],
	"bedroom": [-3.37, -0.77, -6.2, -2.52, "floor_wood", "wall", L_BED],
	"storage": [-3.37, -0.77, -10.6, -6.32, "floor_hall", "wall", L_STORAGE],
	"living": [0.77, 3.8, -6.2, 0.0, "floor_wood", "wall", L_LIVING],
	"closet": [0.77, 2.0, -8.6, -6.32, "floor_hall", "wall", L_CLOSET],
}

var doors := {}                        ## name -> Door
var lamps := {}                        ## room -> Array of {light, bulb}
var front_door: Interactable
var phone: Interactable
var _panes: Array[MeshInstance3D] = []


func _ready() -> void:
	_ready_kit()
	_floors_and_ceilings()
	_walls()
	_openings()
	_furniture()
	_lamps()
	_collision_floor()
	flush()


func _spec(room: String) -> Array:
	var r: Array = ROOMS[room]
	return [r[5], r[6]]


func _layer(room: String) -> int:
	return ROOMS[room][6]


# --- shell ------------------------------------------------------------------

func _floors_and_ceilings() -> void:
	for name in ROOMS:
		var r: Array = ROOMS[name]
		var layer: int = r[6]
		var w: float = r[1] - r[0]
		var d: float = r[3] - r[2]
		var cx: float = (r[0] + r[1]) * 0.5
		var cz: float = (r[2] + r[3]) * 0.5
		if name == "living":                         # tiled kitchen end, boards in the lounge
			box(Vector3(cx, -0.05, -1.2), Vector3(w, 0.1, 2.4), [], {"py": ["tile", layer]}, false)
			box(Vector3(cx, -0.05, -4.3), Vector3(w, 0.1, 3.8), [], {"py": [r[4], layer]}, false)
		else:
			box(Vector3(cx, -0.05, cz), Vector3(w, 0.1, d), [], {"py": [r[4], layer]}, false)
		box(Vector3(cx, H + 0.05, cz), Vector3(w, 0.1, d), [], {"ny": ["ceiling", layer]}, false)


func _collision_floor() -> void:
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(9.0, 0.4, 12.5)
	shape.shape = bs
	shape.position = Vector3(0.2, -0.2, -5.2)
	_body.add_child(shape)
	var roof := CollisionShape3D.new()              # nothing can climb out through the ceiling
	var rs := BoxShape3D.new()
	rs.size = Vector3(9.0, 0.4, 12.5)
	roof.shape = rs
	roof.position = Vector3(0.2, H + 0.2, -5.2)
	_body.add_child(roof)


## A wall running along Z at x = xc. `openings`: [{c, w, sill, top}] along Z.
func _wall_x(xc: float, z0: float, z1: float, openings: Array, west: Array, east: Array) -> void:
	_wall(true, xc, z0, z1, openings, west, east)


## A wall running along X at z = zc. `west` is the -Z face, `east` the +Z face.
func _wall_z(zc: float, x0: float, x1: float, openings: Array, neg: Array, pos: Array) -> void:
	_wall(false, zc, x0, x1, openings, neg, pos)


func _wall(along_z: bool, fixed: float, a0: float, a1: float, openings: Array, neg: Array, pos: Array) -> void:
	var edge: Array = neg if not neg.is_empty() else pos
	var faces := {}
	if along_z:
		faces = {"nx": neg, "px": pos, "pz": edge, "nz": edge, "py": edge, "ny": edge}
	else:
		faces = {"nz": neg, "pz": pos, "px": edge, "nx": edge, "py": edge, "ny": edge}
	var ops := openings.duplicate()
	ops.sort_custom(func(p: Dictionary, q: Dictionary) -> bool: return p["c"] < q["c"])
	var cur := a0
	for o in ops:
		var lo: float = o["c"] - o["w"] * 0.5
		var hi: float = o["c"] + o["w"] * 0.5
		_slab(along_z, fixed, cur, lo, 0.0, H, faces)
		if o["sill"] > 0.0:
			_slab(along_z, fixed, lo, hi, 0.0, o["sill"], faces)
		_slab(along_z, fixed, lo, hi, o["top"], H, faces)
		cur = hi
	_slab(along_z, fixed, cur, a1, 0.0, H, faces)


func _slab(along_z: bool, fixed: float, a0: float, a1: float, y0: float, y1: float, faces: Dictionary) -> void:
	if a1 - a0 < 0.001 or y1 - y0 < 0.001:
		return
	var mid := (a0 + a1) * 0.5
	var len := a1 - a0
	var cy := (y0 + y1) * 0.5
	if along_z:
		box(Vector3(fixed, cy, mid), Vector3(T, y1 - y0, len), [], faces)
	else:
		box(Vector3(mid, cy, fixed), Vector3(len, y1 - y0, T), [], faces)


func _opening(c: float, w: float, sill := 0.0, top := DOOR_H) -> Dictionary:
	return {"c": c, "w": w, "sill": sill, "top": top}


func _walls() -> void:
	var none: Array = []
	var bath := _spec("bath")
	var bed := _spec("bedroom")
	var sto := _spec("storage")
	var liv := _spec("living")
	var clo := _spec("closet")
	var cor := _spec("corridor")

	# Outer west wall, one run per room so each inside face gets its own room.
	_wall_x(-3.43, -2.46, 0.12, [_opening(-1.2, 0.5, 1.55, 2.1)], none, bath)
	_wall_x(-3.43, -6.26, -2.46, [_opening(-4.4, 1.2, 0.9, 2.1)], none, bed)
	_wall_x(-3.43, -10.72, -6.26, [_opening(-8.4, 0.8, 1.0, 2.0)], none, sto)
	# Outer east wall (the living room end of the building).
	_wall_x(3.86, -6.26, 0.12, [_opening(-1.2, 0.9, 0.95, 2.1), _opening(-4.4, 1.4, 0.9, 2.1)], liv, none)
	# Corridor walls with the doors.
	_wall_x(-0.71, -2.46, 0.12, [_opening(-1.2, 0.8)], bath, cor)
	_wall_x(-0.71, -6.26, -2.46, [_opening(-3.5, 0.85)], bed, cor)
	_wall_x(-0.71, -10.72, -6.26, [_opening(-7.6, 0.85)], sto, cor)
	_wall_x(0.71, -6.26, 0.12, [_opening(-3.0, 1.0)], cor, liv)
	_wall_x(0.71, -8.72, -6.26, [_opening(-7.4, 0.7)], cor, clo)
	_wall_x(0.71, -10.72, -8.72, [], cor, none)
	# South wall (front door in the corridor).
	_wall_z(0.06, -3.49, -0.71, [], bath, none)
	_wall_z(0.06, -0.71, 0.71, [_opening(0.0, 0.9)], cor, none)
	_wall_z(0.06, 0.71, 3.92, [], liv, none)
	# North wall: storage, and the corridor with its small window.
	_wall_z(-10.66, -3.49, -0.71, [], none, sto)
	_wall_z(-10.66, -0.71, 0.71, [_opening(0.0, 0.7, 1.0, 2.0)], none, cor)
	# Partitions between the west rooms.
	_wall_z(-2.46, -3.37, -0.77, [], bed, bath)
	_wall_z(-6.26, -3.37, -0.77, [], sto, bed)
	# Living room north wall, closet walls.
	_wall_z(-6.26, 0.71, 2.12, [], clo, liv)
	_wall_z(-6.26, 2.12, 3.92, [], none, liv)
	_wall_z(-8.66, 0.71, 2.12, [], none, clo)
	_wall_x(2.06, -8.72, -6.2, [], clo, none)


func _openings() -> void:
	# Doors: [name, hinge x, hinge z, width, open angle, layers]
	var both_bath := L_CORR | L_BATH
	_door("bath", -0.71, -0.8, 0.8, 100.0, both_bath)
	_door("bedroom", -0.71, -3.075, 0.85, 100.0, L_CORR | L_BED)
	_door("storage", -0.71, -7.175, 0.85, 100.0, L_CORR | L_STORAGE)
	_door("living", 0.71, -2.5, 1.0, -100.0, L_CORR | L_LIVING)
	_door("closet", 0.71, -7.05, 0.7, -100.0, L_CORR | L_CLOSET)
	doors["living"].set_open(true, false)

	# The front door never opens (yet): a flat slab with a prompt.
	var fd := MeshInstance3D.new()
	fd.mesh = RoomKit.box_mesh(Vector3(0.86, DOOR_H - 0.04, 0.05), "dark_wood")
	fd.position = Vector3(0.0, DOOR_H * 0.5, 0.06)
	fd.layers = L_CORR
	add_child(fd)
	front_door = _interactable("Front door", Vector3(0.9, DOOR_H, 0.3), Vector3(0, DOOR_H * 0.5, -0.1))
	front_door.interacted.connect(func() -> void: said.emit("I'm not going out today."))
	box(Vector3(0.0, DOOR_H * 0.5, 0.06), Vector3(0.9, DOOR_H, 0.1), [], {}, true)   # collision only; the leaf above is the visual

	# Windows: a grey glowing pane outside each opening, plus a sill and a frame.
	_window(-3.37, -1.2, 0.5, 1.55, 2.1, true, L_BATH)
	_window(-3.37, -4.4, 1.2, 0.9, 2.1, true, L_BED)
	_window(-3.37, -8.4, 0.8, 1.0, 2.0, true, L_STORAGE)
	_window(3.8, -1.2, 0.9, 0.95, 2.1, true, L_LIVING)
	_window(3.8, -4.4, 1.4, 0.9, 2.1, true, L_LIVING)
	_window(-10.6, 0.0, 0.7, 1.0, 2.0, false, L_CORR)


## `fixed` is the wall's inside face (x for east/west walls, z for the north wall); `c` the
## window centre along the wall.
func _window(fixed: float, c: float, w: float, sill: float, top: float, on_x_wall: bool, layer: int) -> void:
	var h := top - sill
	var cy := (sill + top) * 0.5
	var pane := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(w, h)
	pane.mesh = quad
	pane.material_override = Mats.glow(Color(0.24, 0.27, 0.32))
	pane.layers = layer
	var inward := 0.0
	if on_x_wall:
		inward = 1.0 if fixed < 0.0 else -1.0             # toward the room
		pane.position = Vector3(fixed - inward * 0.15, cy, c)
		pane.rotation.y = inward * PI / 2.0                 # quad faces +Z; turn it to face the room
	else:
		pane.position = Vector3(c, cy, fixed - 0.15)
	add_child(pane)
	_panes.append(pane)
	var bar := 0.05
	var f := ["white", layer]
	if on_x_wall:
		var x := fixed + inward * 0.02
		box(Vector3(x, top, c), Vector3(0.05, bar, w + 0.1), f, {}, false)
		box(Vector3(fixed + inward * 0.06, sill, c), Vector3(0.12, bar, w + 0.12), f, {}, false)
		box(Vector3(x, cy, c), Vector3(0.03, h, 0.03), f, {}, false)
	else:
		var z := fixed + 0.02
		box(Vector3(c, top, z), Vector3(w + 0.1, bar, 0.05), f, {}, false)
		box(Vector3(c, sill, fixed + 0.06), Vector3(w + 0.12, bar, 0.12), f, {}, false)
		box(Vector3(c, cy, z), Vector3(0.03, h, 0.03), f, {}, false)


func set_window_light(color: Color) -> void:
	for p in _panes:
		(p.material_override as StandardMaterial3D).albedo_color = color


## A hinged door on an X-wall (wall running along Z). The hinge is the bottom of the
## hinge edge; the leaf extends toward -Z. `open_angle` > 0 swings it west, < 0 east.
func _door(name: String, hx: float, hz: float, width: float, open_angle: float, layers: int) -> void:
	var pivot := Node3D.new()
	pivot.position = Vector3(hx, 0.0, hz)
	pivot.rotation.y = PI / 2.0                        # local +X now points to -Z
	add_child(pivot)

	var d := Door.new()
	d.open_angle = open_angle
	d.collision_layer = 1 | 2
	d.position = Vector3(0, DOOR_H * 0.5, 0)
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(width - 0.04, DOOR_H - 0.04, 0.1)
	shape.shape = bs
	shape.position = Vector3(width * 0.5, 0, 0)
	d.add_child(shape)
	var leaf := MeshInstance3D.new()
	leaf.mesh = RoomKit.box_mesh(Vector3(width - 0.04, DOOR_H - 0.04, 0.045), "dark_wood")
	leaf.material_override = Mats.get_mat("dark_wood")
	leaf.layers = layers
	leaf.position = Vector3(width * 0.5, 0, 0)
	d.add_child(leaf)
	var handle := MeshInstance3D.new()
	handle.mesh = RoomKit.box_mesh(Vector3(0.12, 0.03, 0.09), "metal")
	handle.material_override = Mats.get_mat("metal")
	handle.layers = layers
	handle.position = Vector3(width - 0.1, -0.05, 0)
	d.add_child(handle)
	pivot.add_child(d)

	var catch_body := DoorCatch.new()
	catch_body.door = d
	catch_body.collision_layer = 2
	catch_body.collision_mask = 0
	var cshape := CollisionShape3D.new()
	var cbox := BoxShape3D.new()
	cbox.size = Vector3(width - 0.1, DOOR_H - 0.1, 0.4)
	cshape.shape = cbox
	catch_body.add_child(cshape)
	catch_body.position = Vector3(width * 0.5, DOOR_H * 0.5, 0)
	pivot.add_child(catch_body)
	doors[name] = d


# --- furniture ----------------------------------------------------------------

func _p(room: String, center: Vector3, size: Vector3, mat: String, yaw := 0.0, collide := true) -> void:
	box(center, size, [mat, _layer(room)], {}, collide, yaw)


func _table(room: String, c: Vector3, w: float, d: float, h: float, mat: String) -> void:
	_p(room, Vector3(c.x, h - 0.02, c.z), Vector3(w, 0.04, d), mat)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_p(room, Vector3(c.x + sx * (w * 0.5 - 0.04), (h - 0.04) * 0.5, c.z + sz * (d * 0.5 - 0.04)),
				Vector3(0.05, h - 0.04, 0.05), mat, 0.0, false)


func _chair(room: String, c: Vector3, yaw: float) -> void:
	var b := Basis(Vector3.UP, yaw)
	_p(room, c + Vector3(0, 0.45, 0), Vector3(0.42, 0.04, 0.42), "dark_wood", yaw)
	_p(room, c + b * Vector3(0, 0.72, 0.19), Vector3(0.42, 0.5, 0.04), "dark_wood", yaw, false)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_p(room, c + b * Vector3(sx * 0.18, 0.22, sz * 0.18), Vector3(0.04, 0.44, 0.04), "dark_wood", yaw, false)


func _furniture() -> void:
	# Corridor
	_p("corridor", Vector3(-0.48, 0.2, -0.7), Vector3(0.3, 0.4, 0.7), "dark_wood")            # shoe rack
	_p("corridor", Vector3(0.55, 1.45, -0.55), Vector3(0.1, 0.9, 0.3), "paint", 0.0, false)   # coats on the hooks
	_p("corridor", Vector3(0.64, 1.45, -9.4), Vector3(0.03, 1.1, 0.6), "glass", 0.0, false)   # long mirror
	_p("corridor", Vector3(0.0, 0.36, -10.35), Vector3(0.55, 0.72, 0.4), "dark_wood")         # phone table
	_p("corridor", Vector3(0.0, 0.76, -10.35), Vector3(0.24, 0.08, 0.2), "black", 0.0, false) # landline
	_p("corridor", Vector3(-0.64, 1.5, -5.4), Vector3(0.03, 0.5, 0.4), "dark_wood", 0.0, false)   # framed picture
	_p("corridor", Vector3(-0.64, 1.5, -9.6), Vector3(0.03, 0.4, 0.3), "dark_wood", 0.0, false)

	# Kitchen end of the living room
	_p("living", Vector3(1.12, 0.9, -0.5), Vector3(0.65, 1.8, 0.65), "white")                  # fridge
	_p("living", Vector3(1.07, 0.45, -1.55), Vector3(0.6, 0.9, 1.3), "dark_wood")               # counter
	_p("living", Vector3(1.05, 0.92, -1.55), Vector3(0.64, 0.04, 1.34), "metal", 0.0, false)
	_p("living", Vector3(1.0, 1.7, -1.55), Vector3(0.35, 0.6, 1.1), "dark_wood", 0.0, false)  # wall cupboard
	_table("living", Vector3(2.7, 0, -1.2), 0.9, 0.8, 0.75, "dark_wood")
	_chair("living", Vector3(2.7, 0, -0.55), 0.0)
	_chair("living", Vector3(2.7, 0, -1.85), PI)
	_p("living", Vector3(2.55, 0.78, -1.2), Vector3(0.22, 0.03, 0.22), "white", 0.0, false)   # plate
	_p("living", Vector3(2.85, 0.78, -1.2), Vector3(0.22, 0.03, 0.22), "white", 0.0, false)   # a second plate

	# Living room
	_p("living", Vector3(2.3, 0.22, -3.7), Vector3(2.0, 0.44, 0.9), "fabric")                  # sofa
	_p("living", Vector3(2.3, 0.62, -3.24), Vector3(2.0, 0.5, 0.18), "fabric", 0.0, false)
	_p("living", Vector3(1.4, 0.45, -3.7), Vector3(0.2, 0.3, 0.9), "fabric", 0.0, false)
	_p("living", Vector3(3.2, 0.45, -3.7), Vector3(0.2, 0.3, 0.9), "fabric", 0.0, false)
	_p("living", Vector3(2.3, 0.007, -4.9), Vector3(2.2, 0.014, 1.5), "fabric", 0.0, false)    # rug
	_table("living", Vector3(2.3, 0, -4.8), 0.9, 0.5, 0.4, "dark_wood")
	_p("living", Vector3(2.3, 0.22, -5.95), Vector3(1.3, 0.44, 0.4), "dark_wood")              # TV stand
	_p("living", Vector3(2.3, 0.75, -6.0), Vector3(1.0, 0.58, 0.06), "black", 0.0, false)      # TV
	_p("living", Vector3(0.95, 0.9, -5.65), Vector3(0.3, 1.8, 1.0), "dark_wood")               # bookshelf
	_table("living", Vector3(1.15, 0, -4.45), 0.6, 1.2, 0.75, "dark_wood")                     # desk
	_p("living", Vector3(1.2, 0.87, -4.4), Vector3(0.3, 0.02, 0.22), "metal", 0.0, false)      # laptop
	_chair("living", Vector3(1.85, 0, -4.45), PI / 2.0)

	# Bedroom
	_p("bedroom", Vector3(-2.1, 0.2, -5.2), Vector3(1.5, 0.4, 2.0), "dark_wood")               # bed frame
	_p("bedroom", Vector3(-2.1, 0.5, -5.2), Vector3(1.4, 0.2, 1.9), "fabric", 0.0, false)      # mattress
	_p("bedroom", Vector3(-2.1, 0.66, -5.95), Vector3(0.55, 0.12, 0.32), "white", 0.0, false)  # pillow
	_p("bedroom", Vector3(-3.15, 0.25, -5.95), Vector3(0.4, 0.5, 0.4), "dark_wood")             # nightstand
	_p("bedroom", Vector3(-3.0, 1.0, -3.15), Vector3(0.6, 2.0, 1.1), "dark_wood")              # wardrobe

	# Bathroom
	_p("bath", Vector3(-2.95, 0.28, -1.55), Vector3(0.75, 0.56, 1.4), "white")                 # bath
	_p("bath", Vector3(-3.0, 0.2, -0.5), Vector3(0.4, 0.4, 0.6), "white")                      # toilet
	_p("bath", Vector3(-3.15, 0.65, -0.5), Vector3(0.1, 0.4, 0.4), "white", 0.0, false)
	_p("bath", Vector3(-1.6, 0.85, -2.2), Vector3(0.5, 0.12, 0.38), "white")                   # basin
	_p("bath", Vector3(-1.6, 0.4, -2.22), Vector3(0.12, 0.8, 0.12), "white", 0.0, false)
	_p("bath", Vector3(-1.6, 1.55, -2.38), Vector3(0.5, 0.7, 0.03), "glass", 0.0, false)       # mirror

	# Dad's room: boxes and an old armchair
	_p("storage", Vector3(-3.0, 0.2, -10.3), Vector3(0.6, 0.4, 0.5), "cardboard")
	_p("storage", Vector3(-3.0, 0.6, -10.3), Vector3(0.5, 0.4, 0.45), "cardboard")
	_p("storage", Vector3(-2.3, 0.25, -10.3), Vector3(0.7, 0.5, 0.5), "cardboard")
	_p("storage", Vector3(-3.1, 0.22, -9.5), Vector3(0.5, 0.44, 0.6), "cardboard")
	_p("storage", Vector3(-1.5, 0.35, -9.1), Vector3(0.8, 0.7, 0.8), "fabric", 0.4)            # armchair
	_p("storage", Vector3(-3.3, 1.45, -6.9), Vector3(0.03, 0.5, 0.4), "dark_wood", 0.0, false) # old family photo
	_p("closet", Vector3(1.4, 1.7, -7.5), Vector3(0.03, 0.03, 1.8), "metal", 0.0, false)       # clothes rail


# --- lights -----------------------------------------------------------------

func _lamps() -> void:
	_lamp("corridor", Vector3(0, H - 0.08, -2.6), Color(1.0, 0.82, 0.58), 0.9, 4.6)
	_lamp("corridor", Vector3(0, H - 0.08, -7.4), Color(1.0, 0.82, 0.58), 0.8, 4.6)
	_lamp("bath", Vector3(-2.05, H - 0.08, -1.2), Color(0.85, 0.92, 1.0), 1.0, 3.6)
	_lamp("bedroom", Vector3(-2.05, H - 0.08, -4.4), Color(1.0, 0.78, 0.55), 0.9, 4.2)
	_lamp("storage", Vector3(-2.05, H - 0.08, -8.4), Color(1.0, 0.72, 0.48), 0.8, 4.6)
	_lamp("living", Vector3(2.3, H - 0.08, -3.1), Color(1.0, 0.82, 0.6), 1.0, 5.6)
	_lamp("closet", Vector3(1.4, H - 0.08, -7.5), Color(1.0, 0.75, 0.5), 0.4, 2.2)

	_switch("corridor", Vector3(0.635, 1.3, -0.4), Vector3(-1, 0, 0))
	_switch("bath", Vector3(-0.785, 1.3, -0.6), Vector3(1, 0, 0))
	_switch("bedroom", Vector3(-0.785, 1.3, -3.0), Vector3(1, 0, 0))
	_switch("storage", Vector3(-0.785, 1.3, -6.9), Vector3(1, 0, 0))
	_switch("living", Vector3(0.785, 1.3, -2.1), Vector3(-1, 0, 0))


func _lamp(room: String, pos: Vector3, color: Color, energy: float, range_m: float) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_m
	light.omni_attenuation = 1.3
	light.light_cull_mask = _layer(room)
	light.shadow_bias = 0.04
	light.shadow_normal_bias = 1.0
	add_child(light)
	var bulb := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.07
	sphere.height = 0.14
	sphere.radial_segments = 12
	sphere.rings = 6
	bulb.mesh = sphere
	bulb.material_override = Mats.glow(color.lerp(Color.WHITE, 0.5))
	bulb.position = pos + Vector3(0, 0.03, 0)
	bulb.layers = _layer(room)
	add_child(bulb)
	if not lamps.has(room):
		lamps[room] = []
	(lamps[room] as Array).append({"light": light, "bulb": bulb, "energy": energy})


func _switch(room: String, pos: Vector3, facing: Vector3) -> void:
	box(pos, Vector3(0.03 if facing.x != 0.0 else 0.1, 0.14, 0.1 if facing.x != 0.0 else 0.03), ["white", _layer(room)], {}, false)
	var s := _interactable("Light", Vector3(0.3, 0.3, 0.3), pos)
	s.interacted.connect(func() -> void: toggle_room(room))


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
			(l["light"] as Light3D).shadow_enabled = level >= 2 or (level == 1 and room == "corridor")


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


# --- helpers for the world ---------------------------------------------------

func spawn_point() -> Vector3:
	return Vector3(0.0, 0.05, -0.8)


func spawn_yaw() -> float:
	return 0.0                                          # facing north, down the corridor


## Named positions for look-dev and tests: name -> [position, yaw].
func debug_spots() -> Dictionary:
	return {
		"door": [Vector3(0.0, 0.05, -0.8), 0.0],
		"mid": [Vector3(0.0, 0.05, -5.0), 0.0],
		"end": [Vector3(0.0, 0.05, -9.8), PI],
		"living": [Vector3(1.2, 0.05, -2.9), -0.4],
		"kitchen": [Vector3(1.7, 0.05, -2.85), PI + 0.1],
		"bedroom": [Vector3(-1.1, 0.05, -3.3), 0.48],
		"bath": [Vector3(-1.2, 0.05, -0.3), 0.71],
		"storage": [Vector3(-1.2, 0.05, -7.0), 0.48],
		"phone": [Vector3(0.0, 0.05, -8.4), 0.0],
	}
