class_name Lighthouse
extends RoomKit
## The tower, built from code: a tall, tapered, whitewashed masonry tower with a gallery and a glazed lantern, its
## door facing the landing stair. Everything the keeper uses is visible from the entrance:
##   ahead, a door to the keeper's small bedroom (a lean-to at the back);
##   on the right, a door to the oil store, with a stair down to the store underground;
##   on the left, the stone spiral stair, which climbs round the wall to the lantern room and the gallery.
## Local frame: origin at the tower's centre on the ground; +Z is the door side (seaward); +X is on your right as
## you face the door from outside (and as you walk in). Angles are degrees from +Z toward +X.

const R_IN := 2.75              ## inside radius, constant all the way up
const R_BASE := 3.75            ## outside radius at the ground
const R_TOP := 3.05             ## outside radius at the top of the masonry
const TOP_Y := 17.4             ## the lantern-room floor (top of the stair)
const FOOT_Y := -1.5            ## the masonry goes this far below the ground
const FLOOR_Y := 0.03
const DOOR_H := 2.1
const STAIR_R := 1.75           ## inner edge of the spiral stair; its outer edge is the wall
const PITCH := 5.8              ## rise per full turn of the stair
const TURNS := 3.0
const STAIR_START := -15.0      ## the first step, just left of the entrance; the stair climbs toward -X
const STEPS_PER_TURN := 24
const HOLE := [-15.0, 135.0]    ## the lantern-room floor is open above the last part of the stair
const OPENINGS := [[0.0, 1.1], [90.0, 1.0], [180.0, 1.0]]     ## [angle, width]: entrance, oil store, bedroom
const GALLERY_DOOR := -90.0
const LANTERN_R := 2.85
const RAIL_R := 3.95
const GALLERY_R := 4.1
const LANTERN_Y := 19.15        ## the lamp's height
const STORE_FLOOR_Y := -3.4
const SHED_STAIR_X := 4.3       ## the oil-store stair runs down toward -Z along this x
const SHED_STAIR_W := 1.1
const SHED_STAIR_TOP_Z := -0.6
const SHED_STAIR_BOTTOM_Z := -4.4
const STORE_FRONT_Z := -5.2
## The terrain inside this local rectangle is cut away for the oil-store stair (see Island.cut_terrain).
const TERRAIN_HOLE := Rect2(3.75, -4.4, 1.1, 3.8)

var entrance_door: Door
var stair_door: Door            ## the door to the oil store and the stair down
var bedroom_door: Door
var store: StoreRoom
var _faces := PackedVector3Array()
var _glass_mat: StandardMaterial3D
var _glazing_mat: StandardMaterial3D
var _beam: Node3D
var _spot: SpotLight3D
var _gate_light: OmniLight3D
var _gate_mesh: MeshInstance3D
var _halo: MeshInstance3D
var _window_out: StandardMaterial3D
var _window_in: StandardMaterial3D


func _ready() -> void:
	_init_materials()
	_window_out = StandardMaterial3D.new()
	_window_out.albedo_color = Color(0.05, 0.05, 0.055)
	_window_out.roughness = 0.15
	_window_in = StandardMaterial3D.new()
	_window_in.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_window_in.albedo_color = Color(0.75, 0.75, 0.75)
	_build_shell()
	_build_floors()
	_build_spiral()
	_build_lantern_room()
	_build_doors()
	_build_bedroom()
	_build_shed()
	_build_ground_floor_props()
	_build_interior_lights()
	_build_beam_and_lamps()
	_flush_batches()
	var body := MeshBuilder.body_from(_faces)
	add_child(body)
	_build_store()


static func r_out(y: float) -> float:
	return R_BASE + (R_TOP - R_BASE) * clampf(y / TOP_Y, 0.0, 1.0)


## Height of the stair's walking line, `t` degrees round from its first step.
static func stair_y(t: float) -> float:
	return PITCH * t / 360.0


static func stair_angle(t: float) -> float:
	return STAIR_START - t


static func _p(a: float, r: float, y: float) -> Vector3:
	return MeshBuilder.polar(a, r, y)


static func _in_cut(a: float, cuts: Array) -> bool:
	for c in cuts:
		var mid: float = (c[0] + c[1]) / 2.0
		var half: float = (c[1] - c[0]) / 2.0
		if absf(wrapf(a - mid, -180.0, 180.0)) < half:
			return true
	return false


func _add(b: MeshBuilder, mat: Material, layers: int) -> void:
	if b.is_empty():
		return
	add_child(b.instance(mat, layers))
	if b.collide:
		_faces.append_array(b.faces)


# --- the masonry shell -----------------------------------------------------------------------------------------

func _build_shell() -> void:
	var outer := MeshBuilder.new()
	var inner := MeshBuilder.new()
	var jamb := MeshBuilder.new()
	var cuts: Array = []
	var angles: Array = []
	var segs := 48
	for k in segs:
		angles.append(-180.0 + 360.0 * k / segs)
	for op in OPENINGS:
		var half := rad_to_deg(asin(float(op[1]) / 2.0 / R_IN))
		cuts.append([float(op[0]) - half, float(op[0]) + half])
		angles.append(wrapf(float(op[0]) - half, -180.0, 180.0))
		angles.append(wrapf(float(op[0]) + half, -180.0, 180.0))
	angles.sort()
	angles.append(angles[0] + 360.0)
	var slope := (R_BASE - R_TOP) / TOP_Y
	var on := func(a: float) -> Vector3: return (MeshBuilder.radial(a) + Vector3(0, slope, 0)).normalized()
	var bands := [[FOOT_Y, 0.0], [0.0, DOOR_H], [DOOR_H, TOP_Y]]
	for bi in bands.size():
		var y0: float = bands[bi][0]
		var y1: float = bands[bi][1]
		for i in angles.size() - 1:
			var a0: float = angles[i]
			var a1: float = angles[i + 1]
			if a1 - a0 < 0.01:
				continue
			var mid := (a0 + a1) / 2.0
			if bi == 1 and _in_cut(mid, cuts):
				# the opening: a stone soffit over it and a threshold under it
				jamb.quad(_p(a0, R_IN, y1), _p(a1, R_IN, y1), _p(a1, r_out(y1), y1), _p(a0, r_out(y1), y1), Vector3.DOWN)
				jamb.quad(_p(a0, R_IN - 0.05, FLOOR_Y), _p(a1, R_IN - 0.05, FLOOR_Y), _p(a1, r_out(0) + 0.05, FLOOR_Y),
						_p(a0, r_out(0) + 0.05, FLOOR_Y), Vector3.UP)
				continue
			outer.quad_n(_p(a0, r_out(y0), y0), _p(a1, r_out(y0), y0), _p(a1, r_out(y1), y1), _p(a0, r_out(y1), y1),
					on.call(a0), on.call(a1), on.call(a1), on.call(a0))
			if bi > 0:
				inner.quad_n(_p(a0, R_IN, y0), _p(a1, R_IN, y0), _p(a1, R_IN, y1), _p(a0, R_IN, y1),
						-MeshBuilder.radial(a0), -MeshBuilder.radial(a1), -MeshBuilder.radial(a1), -MeshBuilder.radial(a0))
	for c in cuts:
		for e in [[c[0], 1.0], [c[1], -1.0]]:
			var t: Vector3 = MeshBuilder.radial(e[0] + 90.0) * e[1]
			jamb.quad(_p(e[0], R_IN, 0.0), _p(e[0], r_out(0), 0.0), _p(e[0], r_out(DOOR_H), DOOR_H), _p(e[0], R_IN, DOOR_H), t)
	# The corbel under the gallery, flaring out from the top of the masonry.
	var cy0 := TOP_Y - 1.1
	var cy1 := TOP_Y - 0.35
	for k in segs:
		var a0 := -180.0 + 360.0 * k / segs
		var a1 := a0 + 360.0 / segs
		var n0 := (MeshBuilder.radial(a0) * 0.6 + Vector3.DOWN).normalized()
		var n1 := (MeshBuilder.radial(a1) * 0.6 + Vector3.DOWN).normalized()
		outer.quad_n(_p(a0, r_out(cy0) - 0.02, cy0), _p(a1, r_out(cy0) - 0.02, cy0), _p(a1, GALLERY_R, cy1), _p(a0, GALLERY_R, cy1), n0, n1, n1, n0)
	_add(outer, _whitewash, 1)
	_add(inner, _whitewash, 2)
	_add(jamb, _stone, 3)
	# A darker stone surround round the entrance, as in the old towers.
	var z_face := sqrt(R_BASE * R_BASE - 0.9 * 0.9)
	for sx in [-0.86, 0.86]:
		_batch_box(Vector3(0.26, DOOR_H + 0.3, 0.2), Vector3(sx, (DOOR_H + 0.3) / 2.0, z_face), _stone, 1)
	_batch_box(Vector3(2.0, 0.34, 0.22), Vector3(0, DOOR_H + 0.3, z_face + 0.02), _stone, 1)
	# Slit windows up the stair: dark glass outside, pale daylight inside.
	for t in [150.0, 330.0, 510.0, 690.0, 870.0]:
		var a := stair_angle(t)
		if _in_cut(a, cuts):
			a -= 25.0
		var y := stair_y(t) + 1.5
		_window(a, y)


func _batch_box(size: Vector3, pos: Vector3, mat: Material, layer := 2, basis := Basis()) -> void:
	var box := BoxMesh.new()
	box.size = size
	_batch(box, Transform3D(basis, pos), mat, layer)


func _window(a: float, y: float) -> void:
	var r := r_out(y)
	var n := MeshBuilder.radial(a)
	var basis := Basis.looking_at(-n, Vector3.UP)
	_batch_box(Vector3(0.42, 1.0, 0.06), _p(a, r + 0.005, y), _window_out, 1, basis)
	_batch_box(Vector3(0.6, 1.2, 0.1), _p(a, r + 0.02, y + 0.62), _stone, 1, basis)          # a drip stone over it
	_batch_box(Vector3(0.32, 0.9, 0.04), _p(a, R_IN - 0.01, y), _window_in, 2, basis)


# --- floors ------------------------------------------------------------------------------------------------------

func _build_floors() -> void:
	var ground := MeshBuilder.new()
	ground.ring_sector(0.0, R_IN + 0.04, -180.0, 180.0, FLOOR_Y - 0.3, FLOOR_Y)
	_add(ground, _flags, 2)
	# The lantern-room floor and the gallery: open above the last part of the stair.
	var top := MeshBuilder.new()
	var y0 := TOP_Y - 0.35
	top.ring_sector(0.0, STAIR_R, -180.0, 180.0, y0, TOP_Y)
	top.ring_sector(STAIR_R, R_IN, HOLE[1], HOLE[0] + 360.0, y0, TOP_Y)
	top.ring_sector(R_IN, GALLERY_R, -180.0, 180.0, y0, TOP_Y, 7.5, false)
	_add(top, _flags, 3)


# --- the spiral stair --------------------------------------------------------------------------------------------

func _build_spiral() -> void:
	var steps := MeshBuilder.new(false)
	var n := int(STEPS_PER_TURN * TURNS)
	var dt := 360.0 / STEPS_PER_TURN
	for k in n:
		var t0 := k * dt
		var t1 := (k + 1) * dt
		var top := stair_y((t0 + t1) / 2.0)
		# angles decrease as the stair climbs; ring_sector wants a0 < a1
		steps.ring_sector(STAIR_R, R_IN + 0.12, stair_angle(t1), stair_angle(t0), top - 0.34, top, dt)
	_add(steps, _flags, 2)
	# The walking surface: one smooth helical ramp through the step nosings (a body cannot climb risers).
	var total := 360.0 * TURNS
	var t := 0.0
	var ramp := PackedVector3Array()
	var rail_pts: Array = []
	while t < total - 0.01:
		var t2 := minf(t + 5.0, total)
		var a0 := stair_angle(t)
		var a1 := stair_angle(t2)
		var i0 := _p(a0, STAIR_R - 0.03, stair_y(t))
		var o0 := _p(a0, R_IN + 0.05, stair_y(t))
		var i1 := _p(a1, STAIR_R - 0.03, stair_y(t2))
		var o1 := _p(a1, R_IN + 0.05, stair_y(t2))
		ramp.append_array([i0, o0, o1, i0, o1, i1])
		rail_pts.append(_p(a0, STAIR_R - 0.04, stair_y(t) - 0.3))
		t = t2
	rail_pts.append(_p(stair_angle(total), STAIR_R - 0.04, stair_y(total) - 0.3))
	_faces.append_array(ramp)
	# The inner rail: a continuous wall for the body, iron balusters and a handrail for the eye.
	var rail := MeshBuilder.new()
	rail.collide = true
	rail.ribbon(rail_pts, 1.45)
	_faces.append_array(rail.faces)
	t = 0.0
	while t <= total + 0.01:
		var a := stair_angle(t)
		var y := stair_y(t)
		_batch_box(Vector3(0.035, 0.95, 0.035), _p(a, STAIR_R + 0.05, y + 0.47), _iron, 2)
		if t < total:
			var p0 := _p(a, STAIR_R + 0.05, y + 0.97)
			var p1 := _p(stair_angle(t + dt), STAIR_R + 0.05, stair_y(t + dt) + 0.97)
			_rod(p0, p1, 0.05, 2)
		t += dt
	# Round the hole in the lantern-room floor, where the stair is too deep below for its own rail to guard.
	var guard: Array = []
	var a_g := HOLE[0] + 68.0
	while a_g <= HOLE[1] + 0.01:
		guard.append(_p(a_g, STAIR_R - 0.04, TOP_Y))
		a_g += 7.5
	var radial_guard := [_p(HOLE[1], STAIR_R - 0.04, TOP_Y), _p(HOLE[1], R_IN + 0.05, TOP_Y)]
	var g := MeshBuilder.new()
	g.ribbon(guard, 1.15)
	g.ribbon(radial_guard, 1.15)
	_faces.append_array(g.faces)
	for i in guard.size():
		_batch_box(Vector3(0.035, 1.0, 0.035), guard[i] + Vector3(0, 0.5, 0), _iron, 3)
		if i > 0:
			_rod(guard[i - 1] + Vector3(0, 1.0, 0), guard[i] + Vector3(0, 1.0, 0), 0.05, 3)
	_rod(radial_guard[0] + Vector3(0, 1.0, 0), radial_guard[1] + Vector3(0, 1.0, 0), 0.05, 3)


## A thin bar between two points (handrails, glazing bars, rails).
func _rod(a: Vector3, b: Vector3, thick: float, layer: int, mat: Material = null) -> void:
	var d := b - a
	if d.length() < 0.001:
		return
	var up := Vector3.UP if absf(d.normalized().y) < 0.95 else Vector3.RIGHT
	_batch_box(Vector3(thick, thick, d.length()), (a + b) / 2.0, mat if mat else _iron, layer, Basis.looking_at(d.normalized(), up))


# --- lantern room and gallery ---------------------------------------------------------------------------------

func _build_lantern_room() -> void:
	_glass_mat = StandardMaterial3D.new()
	_glass_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glass_mat.albedo_color = Color(0.07, 0.07, 0.08)
	_glazing_mat = StandardMaterial3D.new()
	_glazing_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glazing_mat.albedo_color = Color(0.12, 0.12, 0.13, 0.35)
	_glazing_mat.roughness = 0.05
	_glazing_mat.metallic_specular = 0.9
	_glazing_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var half := rad_to_deg(asin(0.42 / LANTERN_R))
	var d0 := GALLERY_DOOR - half
	var d1 := GALLERY_DOOR + half
	var base_top := TOP_Y + 0.9
	var glass_top := TOP_Y + 3.2
	var door_top := TOP_Y + 2.05
	# Low iron wall, then the glazing, with a doorway out to the gallery.
	var low := MeshBuilder.new()
	low.ring_sector(LANTERN_R, LANTERN_R + 0.1, d1, d0 + 360.0, TOP_Y, base_top, 7.5)
	_add(low, _iron, 3)
	var glass := MeshBuilder.new(false)
	glass.ring_sector(LANTERN_R + 0.03, LANTERN_R + 0.05, d1, d0 + 360.0, base_top, glass_top, 7.5)
	glass.ring_sector(LANTERN_R + 0.03, LANTERN_R + 0.05, d0, d1, door_top, glass_top, 7.5)
	_add(glass, _glazing_mat, 3)
	var wall := MeshBuilder.new()                  # the body's wall: the whole lantern ring except the doorway
	var ring: Array = []
	var a := d1
	while a <= d0 + 360.0 + 0.01:
		ring.append(_p(a, LANTERN_R + 0.04, TOP_Y))
		a += 7.5
	ring.append(_p(d0 + 360.0, LANTERN_R + 0.04, TOP_Y))
	wall.ribbon(ring, 3.2)
	_faces.append_array(wall.faces)
	# Glazing bars and frame.
	for k in 16:
		var b := -180.0 + k * 22.5
		if absf(wrapf(b - GALLERY_DOOR, -180.0, 180.0)) < half + 1.0:
			continue
		_batch_box(Vector3(0.07, glass_top - base_top, 0.07), _p(b, LANTERN_R + 0.06, (base_top + glass_top) / 2.0), _iron, 3)
	for e in [d0, d1]:
		_batch_box(Vector3(0.09, door_top - TOP_Y, 0.09), _p(e, LANTERN_R + 0.06, (TOP_Y + door_top) / 2.0), _iron, 3)
	for y in [base_top, (base_top + glass_top) / 2.0, glass_top]:
		var b := -180.0
		while b < 180.0:
			_rod(_p(b, LANTERN_R + 0.07, y), _p(b + 15.0, LANTERN_R + 0.07, y), 0.07, 3)
			b += 15.0
	# The roof: a dark cone with a vent ball.
	var roof := MeshBuilder.new(false)
	var apex := Vector3(0, glass_top + 1.35, 0)
	var b2 := -180.0
	while b2 < 180.0:
		var p0 := _p(b2, LANTERN_R + 0.35, glass_top)
		var p1 := _p(b2 + 15.0, LANTERN_R + 0.35, glass_top)
		var nrm := ((p0 + p1) / 2.0 - Vector3(0, glass_top, 0)).normalized() * 0.45 + Vector3.UP
		roof.tri(p0, p1, apex, nrm.normalized(), nrm.normalized(), Vector3.UP)
		roof.tri(p0, p1, Vector3(0, glass_top, 0), Vector3.DOWN, Vector3.DOWN, Vector3.DOWN)
		b2 += 15.0
	_add(roof, _iron, 1)
	var ball := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.28
	sph.height = 0.56
	sph.radial_segments = 10
	sph.rings = 6
	ball.mesh = sph
	ball.material_override = _iron
	ball.position = apex + Vector3(0, 0.3, 0)
	add_child(ball)
	# The lamp: a pedestal and the lens.
	var ped := MeshBuilder.new()
	ped.ring_sector(0.0, 0.45, -180.0, 180.0, TOP_Y, TOP_Y + 1.0, 30.0)
	_add(ped, _iron, 3)
	var lens := MeshBuilder.new(false)
	lens.ring_sector(0.0, 0.72, -180.0, 180.0, TOP_Y + 1.0, TOP_Y + 2.5, 22.5)
	_add(lens, _glass_mat, 3)
	# Gallery railing: posts, two rails, and a full ring wall for the body.
	var b3 := -180.0
	var rail_ring: Array = []
	while b3 <= 180.01:
		rail_ring.append(_p(b3, RAIL_R, TOP_Y))
		b3 += 7.5
	var rw := MeshBuilder.new()
	rw.ribbon(rail_ring, 1.25)
	_faces.append_array(rw.faces)
	for k in 24:
		var c := -180.0 + k * 15.0
		_batch_box(Vector3(0.06, 1.1, 0.06), _p(c, RAIL_R, TOP_Y + 0.55), _iron, 1)
		for y in [0.5, 1.08]:
			_rod(_p(c, RAIL_R, TOP_Y + y), _p(c + 15.0, RAIL_R, TOP_Y + y), 0.05, 1)


# --- doors -------------------------------------------------------------------------------------------------------

func _build_doors() -> void:
	var dh := DOOR_H - 0.06
	var zf := sqrt(R_IN * R_IN - 0.55 * 0.55)
	var h0 := Node3D.new()                              # entrance: hinged on the right so it opens against the free wall,
	h0.position = Vector3(0.55, 0, zf)                  # clear of the foot of the stair on the left
	h0.rotation.y = PI
	add_child(h0)
	entrance_door = make_door(1.1, dh, Vector3(0, FLOOR_Y, 0), h0)
	entrance_door.open_angle = -100.0                   # (mirrored frame: negative swings it in, toward the tower)
	var xs := sqrt(R_IN * R_IN - 0.5 * 0.5)
	var h1 := Node3D.new()                              # oil-store door: width along -Z, swings in toward -X
	h1.position = Vector3(xs, 0, 0.5)
	h1.rotation.y = PI / 2.0
	add_child(h1)
	stair_door = make_door(1.0, dh, Vector3(0, FLOOR_Y, 0), h1)
	var h2 := Node3D.new()                              # bedroom door: width along -X, swings in toward +Z
	h2.position = Vector3(0.5, 0, -xs)
	h2.rotation.y = PI
	add_child(h2)
	bedroom_door = make_door(1.0, dh, Vector3(0, FLOOR_Y, 0), h2)


# --- the keeper's bedroom: a narrow lean-to at the back --------------------------------------------------------

## A wall: its inside on the interior layer, and an outdoor skin pushed out by a few cm on the side `out` points to
## (so the skin never shows inside the room).
func _skin_wall(size: Vector3, pos: Vector3, inside: Material, outside: Material, out: Vector3) -> void:
	_solid(size, pos, inside)
	var skin := BoxMesh.new()
	skin.size = size + Vector3(0.06, 0.06, 0.06) - out.abs() * 0.06
	_batch(skin, Transform3D(Basis(), pos + out * 0.04), outside, 1)


func _build_bedroom() -> void:
	var z_back := -6.35
	var wh := 3.2
	var wy := 2.6 - wh / 2.0                          # walls from 0.6 m below the ground to 2.6 m
	_skin_wall(Vector3(0.3, wh, 3.45), Vector3(-1.45, wy, -4.625), _plaster, _whitewash, Vector3.LEFT)
	_skin_wall(Vector3(0.3, wh, 3.45), Vector3(1.45, wy, -4.625), _plaster, _whitewash, Vector3.RIGHT)
	_skin_wall(Vector3(3.2, wh, 0.3), Vector3(0, wy, z_back + 0.15), _plaster, _whitewash, Vector3.FORWARD)
	_solid(Vector3(2.6, 0.3, 3.5), Vector3(0, FLOOR_Y - 0.15, -4.55), _wood)
	_batch_box(Vector3(2.6, 0.1, 3.4), Vector3(0, 2.45, -4.6), _dark_wood, 2)                    # ceiling
	var tilt := -atan(0.5 / 3.6)
	_batch_box(Vector3(3.5, 0.16, 3.75), Vector3(0, 2.85, -4.75), _dark_wood, 1, Basis(Vector3.RIGHT, tilt))   # roof
	for z in [-3.6, -4.6, -5.6]:
		_batch_box(Vector3(2.6, 0.14, 0.14), Vector3(0, 2.35, z), _dark_wood, 2)
	# A narrow bed, a stove, a table and a chair, a shelf, a small window.
	_solid(Vector3(0.9, 0.42, 1.95), Vector3(-0.83, 0.24, -5.0), _dark_wood)
	_batch_box(Vector3(0.82, 0.14, 1.85), Vector3(-0.83, 0.52, -5.0), _sack, 2)
	_batch_box(Vector3(0.84, 0.06, 1.1), Vector3(-0.83, 0.61, -4.6), _plaster, 2)                # blanket
	_batch_box(Vector3(0.6, 0.12, 0.35), Vector3(-0.83, 0.65, -5.75), _plaster, 2)               # pillow
	_batch_box(Vector3(0.95, 0.8, 0.08), Vector3(-0.83, 0.62, -5.99), _dark_wood, 2)             # headboard
	_solid(Vector3(0.6, 0.7, 0.55), Vector3(0.9, 0.38, -5.75), _iron)                             # stove
	_batch_box(Vector3(0.14, 1.8, 0.14), Vector3(0.9, 1.6, -5.9), _iron, 2)
	_solid(Vector3(0.75, 0.05, 0.6), Vector3(0.85, 0.75, -4.2), _wood)                            # table
	for dx in [-0.32, 0.32]:
		for dz in [-0.25, 0.25]:
			_batch_box(Vector3(0.05, 0.72, 0.05), Vector3(0.85 + dx, 0.37, -4.2 + dz), _dark_wood, 2)
	_solid(Vector3(0.4, 0.05, 0.4), Vector3(0.6, 0.46, -4.75), _dark_wood)                        # chair
	_batch_box(Vector3(0.4, 0.5, 0.05), Vector3(0.6, 0.72, -4.95), _dark_wood, 2)
	_batch_box(Vector3(0.25, 0.05, 1.2), Vector3(1.17, 1.55, -4.4), _wood, 2)                     # shelf
	_batch_box(Vector3(0.12, 0.2, 0.12), Vector3(1.17, 1.68, -4.0), _iron, 2)
	_batch_box(Vector3(0.1, 0.26, 0.18), Vector3(1.17, 1.71, -4.5), _sack, 2)
	_batch_box(Vector3(0.5, 0.45, 0.04), Vector3(0.45, 1.6, z_back + 0.31), _window_in, 2)
	_batch_box(Vector3(0.5, 0.45, 0.04), Vector3(0.45, 1.6, z_back - 0.02), _window_out, 1)
	var lamp := _lamp_mesh(Vector3(0.75, 0.88, -4.1))
	lamp.layers = 2
	add_child(lamp)
	var l := OmniLight3D.new()
	l.position = Vector3(0.6, 1.5, -4.4)
	l.omni_range = 4.6
	l.light_energy = 1.1
	l.light_cull_mask = 2
	add_child(l)


# --- the oil store: a stone shed on the right, with the stair down to the store underground -------------------------

func _build_shed() -> void:
	var wh := 3.8
	var wy := 2.8 - wh / 2.0
	_skin_wall(Vector3(3.5, wh, 0.4), Vector3(4.75, wy, 1.75), _stone, _whitewash, Vector3.BACK)            # north
	_skin_wall(Vector3(0.4, wh, 8.55), Vector3(6.3, wy, -2.325), _stone, _whitewash, Vector3.RIGHT)          # east
	_skin_wall(Vector3(4.2, wh, 0.4), Vector3(4.4, wy, -6.4), _stone, _whitewash, Vector3.FORWARD)             # south
	_skin_wall(Vector3(0.4, wh, 4.0), Vector3(2.5, wy, -4.6), _stone, _whitewash, Vector3.LEFT)             # west, behind the tower
	var tilt := -atan(0.45 / 3.9)
	_batch_box(Vector3(4.1, 0.16, 9.0), Vector3(4.75, 3.12, -2.33), _dark_wood, 1, Basis(Vector3.FORWARD, -tilt))   # roof
	_batch_box(Vector3(3.4, 0.1, 7.75), Vector3(4.4, 2.8, -2.33), _dark_wood, 2)                # ceiling
	# The floor round the stairwell (it also covers the hole cut in the terrain).
	var fy := FLOOR_Y - 0.15
	_solid(Vector3(3.4, 0.3, 2.15), Vector3(4.4, fy, 0.475), _flags)
	_solid(Vector3(3.4, 0.3, 1.8), Vector3(4.4, fy, -5.3), _flags)
	_solid(Vector3(1.05, 0.3, 3.8), Vector3(3.225, fy, -2.5), _flags)
	_solid(Vector3(1.25, 0.3, 3.8), Vector3(5.475, fy, -2.5), _flags)
	# Stone benches round it, stacked with oil cans: the stairwell is a narrow slot between them.
	_solid(Vector3(1.25, 0.9, 7.75), Vector3(5.475, FLOOR_Y + 0.45, -2.325), _stone)
	_solid(Vector3(1.1, 0.9, 0.95), Vector3(4.3, FLOOR_Y + 0.45, 1.075), _stone)
	_solid(Vector3(1.05, 0.9, 5.6), Vector3(3.225, FLOOR_Y + 0.45, -3.4), _stone)
	_solid(Vector3(1.1, 0.9, 1.8), Vector3(4.3, FLOOR_Y + 0.45, -5.3), _stone)
	for i in 9:
		var z := 1.0 - i * 0.85
		var can := CylinderMesh.new()
		can.top_radius = 0.17
		can.bottom_radius = 0.17
		can.height = 0.5
		can.radial_segments = 10
		_batch(can, Transform3D(Basis(), Vector3(5.35 + (i % 2) * 0.35, FLOOR_Y + 1.15, z)), _iron, 2)
	# The stair down: steps to look at, one smooth ramp to walk on.
	var top := Vector3(SHED_STAIR_X, FLOOR_Y, SHED_STAIR_TOP_Z)
	var bot := Vector3(SHED_STAIR_X, STORE_FLOOR_Y, SHED_STAIR_BOTTOM_Z)
	var n := 18
	for k in n:
		var s := (k + 0.5) / n
		var y := lerpf(top.y, bot.y, (k + 1.0) / n) + (top.y - bot.y) / n * 0.75
		_batch_box(Vector3(SHED_STAIR_W, 0.12, (top.z - bot.z) / n + 0.04), Vector3(SHED_STAIR_X, y - 0.06, lerpf(top.z, bot.z, s)), _wood, 2)
	_ramp(top, bot, SHED_STAIR_W)
	var wall_h := 3.43
	var wall_y := -0.27 - wall_h / 2.0
	var wz0 := STORE_FRONT_Z
	var wz1 := SHED_STAIR_TOP_Z
	_solid(Vector3(0.3, wall_h, wz1 - wz0), Vector3(SHED_STAIR_X - SHED_STAIR_W / 2.0 - 0.15, wall_y, (wz0 + wz1) / 2.0), _stone)
	_solid(Vector3(0.3, wall_h, wz1 - wz0), Vector3(SHED_STAIR_X + SHED_STAIR_W / 2.0 + 0.15, wall_y, (wz0 + wz1) / 2.0), _stone)
	_solid(Vector3(SHED_STAIR_W + 0.6, wall_h, 0.3), Vector3(SHED_STAIR_X, wall_y, wz1 + 0.15), _stone)
	_solid(Vector3(SHED_STAIR_W + 0.6, 0.3, wz1 - wz0 + 0.2), Vector3(SHED_STAIR_X, STORE_FLOOR_Y - 0.15, (wz0 + wz1) / 2.0), _flags)
	_batch_box(Vector3(0.5, 0.35, 0.04), Vector3(6.08, 2.1, -1.2), _window_in, 2, Basis(Vector3.UP, PI / 2.0))
	_batch_box(Vector3(0.5, 0.35, 0.04), Vector3(6.52, 2.1, -1.2), _window_out, 1, Basis(Vector3.UP, PI / 2.0))
	var l := OmniLight3D.new()
	l.position = Vector3(4.3, 2.3, 0.2)
	l.omni_range = 4.0
	l.light_energy = 0.7
	l.light_cull_mask = 2
	add_child(l)


## A box collider whose top face runs from a to b (both on the centre line): a walkable slope.
func _ramp(a: Vector3, b: Vector3, width: float) -> void:
	var d := b - a
	var basis := Basis.looking_at(d.normalized(), Vector3.UP)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(width, 0.2, d.length())
	cs.shape = bs
	body.add_child(cs)
	body.transform = Transform3D(basis, (a + b) / 2.0 - basis.y * 0.1)
	add_child(body)


func _build_store() -> void:
	store = StoreRoom.new()
	store.underground = true
	store.position = Vector3(SHED_STAIR_X - StoreRoom.DOOR_X, STORE_FLOOR_Y, STORE_FRONT_Z - StoreRoom.D / 2.0 - StoreRoom.WALL_T)
	add_child(store)


# --- ground floor ------------------------------------------------------------------------------------------------

func _build_ground_floor_props() -> void:
	# On the free wall between the store door and the bedroom door: a barrel, crates, a coil of rope.
	var bp := _p(130.0, 2.2, 0.0)
	var barrel := CylinderMesh.new()
	barrel.top_radius = 0.3
	barrel.bottom_radius = 0.3
	barrel.height = 0.85
	barrel.radial_segments = 12
	_batch(barrel, Transform3D(Basis(), bp + Vector3(0, 0.45, 0)), _dark_wood, 2)
	_collider_box(Vector3(0.6, 0.9, 0.6), bp + Vector3(0, 0.45, 0))
	var cp := _p(150.0, 2.15, 0.0)
	_solid(Vector3(0.6, 0.5, 0.5), cp + Vector3(0, 0.28, 0), _wood, Basis(Vector3.UP, deg_to_rad(150.0)))
	_solid(Vector3(0.45, 0.4, 0.4), cp + Vector3(0, 0.73, 0), _dark_wood, Basis(Vector3.UP, deg_to_rad(160.0)))
	var rp := _p(45.0, 2.2, 0.0)
	var torus := TorusMesh.new()
	torus.inner_radius = 0.18
	torus.outer_radius = 0.38
	torus.rings = 12
	torus.ring_segments = 6
	_batch(torus, Transform3D(Basis(), rp + Vector3(0, 0.1, 0)), _sack, 2)
	_batch(torus, Transform3D(Basis(), rp + Vector3(0, 0.25, 0)), _sack, 2)


func _collider_box(size: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	body.add_child(cs)
	body.position = pos
	add_child(body)


func _build_interior_lights() -> void:
	for p in [Vector3(0, 2.8, 0.3), Vector3(0, 8.5, 0), Vector3(0, 14.0, 0)]:
		var l := OmniLight3D.new()
		l.position = p
		l.omni_range = 7.5
		l.light_energy = 1.25
		l.omni_attenuation = 1.1
		l.light_cull_mask = 2
		add_child(l)
	var lamp := _lamp_mesh(Vector3(0, 2.95, 0.3))
	lamp.layers = 2
	add_child(lamp)
	_batch_box(Vector3(0.02, 0.5, 0.02), Vector3(0, 3.3, 0.3), _iron, 2)


func _lamp_mesh(pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.09
	cyl.bottom_radius = 0.07
	cyl.height = 0.2
	cyl.radial_segments = 8
	mi.mesh = cyl
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color.WHITE
	mi.material_override = m
	mi.position = pos
	return mi


# --- the light ---------------------------------------------------------------------------------------------------

func _build_beam_and_lamps() -> void:
	_beam = Node3D.new()
	_beam.position = Vector3(0, LANTERN_Y, 0)
	_spot = SpotLight3D.new()
	_spot.spot_range = 120.0
	_spot.spot_angle = 12.0
	_spot.light_energy = 8.0
	_spot.light_cull_mask = 1
	_spot.rotation_degrees.x = -3.0
	_beam.add_child(_spot)
	# The visible shafts: two opposite beams, each two crossed quads with a soft additive falloff.
	var bm := _beam_material()
	for back in [0.0, PI]:
		for roll in [0.0, PI / 2.0]:
			var q := QuadMesh.new()
			q.size = Vector2(3.2, 70.0)
			var mi := MeshInstance3D.new()
			mi.mesh = q
			mi.material_override = bm
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var b := Basis(Vector3.UP, back) * Basis(Vector3.FORWARD, roll) * Basis(Vector3.RIGHT, -PI / 2.0)
			mi.transform = Transform3D(b, Basis(Vector3.UP, back) * Vector3(0, 0, -36.5))
			mi.extra_cull_margin = 80.0
			_beam.add_child(mi)
	add_child(_beam)
	# A soft halo round the lantern, as the lamp glows through rain and fog.
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 0.75), Color(1, 1, 1, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	var hm := StandardMaterial3D.new()
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	hm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	hm.albedo_texture = gt
	hm.disable_fog = true
	var hq := QuadMesh.new()
	hq.size = Vector2(8.0, 8.0)
	_halo = MeshInstance3D.new()
	_halo.mesh = hq
	_halo.material_override = hm
	_halo.position = Vector3(0, LANTERN_Y, 0)
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_halo)
	# A lamp over the entrance (outdoor layer).
	var pos := Vector3(0.0, DOOR_H + 0.62, R_BASE + 0.22)
	_gate_mesh = _lamp_mesh(pos)
	_gate_mesh.layers = 1
	add_child(_gate_mesh)
	_batch_box(Vector3(0.05, 0.05, 0.3), pos + Vector3(0, 0.15, -0.12), _iron, 1)
	_gate_light = OmniLight3D.new()
	_gate_light.position = pos + Vector3(0, 0, 0.2)
	_gate_light.omni_range = 8.0
	_gate_light.light_energy = 2.4
	_gate_light.light_cull_mask = 1
	add_child(_gate_light)


## Under a roof: in the tower below the lantern room, in the bedroom, in the oil-store shed, or underground.
func is_indoors(world_pos: Vector3) -> bool:
	var p := to_local(world_pos)
	if p.y < -1.0 and Vector2(p.x, p.z).length() < 16.0:
		return true
	if p.y > TOP_Y - 0.5 or p.y < -1.0:
		return false
	if Vector2(p.x, p.z).length() < R_IN + 0.5:
		return true
	return (absf(p.x) < 1.4 and p.z < -2.6 and p.z > -6.2) or (p.x > 2.6 and p.x < 6.2 and p.z < 1.6 and p.z > -6.3)


func lantern_world() -> Vector3:
	return to_global(Vector3(0, LANTERN_Y, 0)) if is_inside_tree() else position + Vector3(0, LANTERN_Y, 0)


## Additive, unshaded, with a falloff texture: bright at the lantern, fading along the shaft and toward its edges.
func _beam_material() -> StandardMaterial3D:
	var img := Image.create(16, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 16:
			var along := 1.0 - float(y) / 63.0                 # texture top (v = 0) is the far end
			var across := absf(float(x) / 15.0 - 0.5) * 2.0
			var a := (1.0 - smoothstep(0.0, 1.0, along)) * (1.0 - smoothstep(0.15, 1.0, across)) * 0.6
			img.set_pixel(x, y, Color(1, 1, 1, a))
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.disable_fog = true
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	return m


func set_beam(on: bool) -> void:
	_beam.visible = on
	_spot.visible = on
	_halo.visible = on
	_glass_mat.albedo_color = Color.WHITE if on else Color(0.07, 0.07, 0.08)


func set_porch(on: bool) -> void:
	_gate_light.visible = on
	_gate_mesh.visible = on


func apply_shadows(level: int) -> void:
	if store:
		store.apply_shadows(level)


func _process(delta: float) -> void:
	if _beam.visible:
		_beam.rotate_y(-0.45 * delta)
