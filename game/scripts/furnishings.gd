class_name Furnishings
## Furniture, clutter and decay for every room of the flat. Everything is boxes, cylinders and
## soft stains, merged into the flat's batches. Coordinates are in metres. Local frames: a
## prop's front looks along local -Z; `yaw` turns it (yaw 0 faces north, PI/2 faces west).

static func furnish(a: Apartment) -> void:
	_entry(a)
	_kitchen(a)
	_living(a)
	_hall(a)
	_bath(a)
	_storage(a)
	_bed1(a)
	_bed2(a)
	_anomalies(a)
	_spots(a)


# --- generic pieces --------------------------------------------------------------------

static func _at(c: Vector3, yaw: float, off: Vector3) -> Vector3:
	return c + Basis(Vector3.UP, yaw) * off


static func _p(a: Apartment, cell: String, c: Vector3, size: Vector3, mat: String, yaw := 0.0, collide := true) -> void:
	a.prop(cell, c, size, mat, yaw, collide)


const TABLES := {"0.90,1.50,0.75": "table_0_9x1_5x0_75", "1.30,0.60,0.74": "table_1_3x0_6x0_74", "0.60,1.20,0.74": "table_0_6x1_2x0_74", "1.00,0.55,0.42": "table_1_0x0_55x0_42"}


static func _table(a: Apartment, cell: String, c: Vector3, w: float, d: float, h: float, mat: String, yaw := 0.0) -> void:
	var key := "%.2f,%.2f,%.2f" % [w, d, h]
	if TABLES.has(key) and a.place_model(TABLES[key], cell, c, yaw):
		a.collider(_at(c, yaw, Vector3(0, h - 0.02, 0)), Vector3(w, 0.04, d), yaw)
		a.blob_shadow(cell, c, w + 0.3, d + 0.3)
		return
	_p(a, cell, _at(c, yaw, Vector3(0, h - 0.02, 0)), Vector3(w, 0.04, d), mat, yaw)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_p(a, cell, _at(c, yaw, Vector3(sx * (w * 0.5 - 0.04), (h - 0.04) * 0.5, sz * (d * 0.5 - 0.04))), Vector3(0.05, h - 0.04, 0.05), mat, yaw, false)
	a.blob_shadow(cell, c, w + 0.3, d + 0.3)


static func _chair(a: Apartment, cell: String, c: Vector3, yaw: float, mat := "dark_wood") -> void:
	if a.place_model("chair", cell, c, yaw):
		a.collider(_at(c, yaw, Vector3(0, 0.45, 0)), Vector3(0.42, 0.04, 0.42), yaw)
		a.blob_shadow(cell, c, 0.55, 0.55)
		return
	_p(a, cell, _at(c, yaw, Vector3(0, 0.45, 0)), Vector3(0.42, 0.04, 0.42), mat, yaw)
	_p(a, cell, _at(c, yaw, Vector3(0, 0.72, 0.19)), Vector3(0.42, 0.5, 0.04), mat, yaw, false)
	_p(a, cell, _at(c, yaw, Vector3(0, 0.84, 0.19)), Vector3(0.34, 0.1, 0.05), mat, yaw, false)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_p(a, cell, _at(c, yaw, Vector3(sx * 0.18, 0.22, sz * 0.18)), Vector3(0.04, 0.44, 0.04), mat, yaw, false)
	a.blob_shadow(cell, c, 0.55, 0.55)


static func _sofa(a: Apartment, cell: String, c: Vector3, yaw: float, w: float, mat := "fabric") -> void:
	if absf(w - 2.1) < 0.01 and a.place_model("sofa_2_1", cell, c, yaw):
		a.collider(_at(c, yaw, Vector3(0, 0.45, 0)), Vector3(w, 0.9, 0.92), yaw)
		a.blob_shadow(cell, c, w + 0.4, 1.3)
		return
	_p(a, cell, _at(c, yaw, Vector3(0, 0.2, 0)), Vector3(w, 0.3, 0.9), "dark_wood", yaw)
	for i in 2:                                                              # seat cushions
		var sx := (-0.5 + i) * (w - 0.4) * 0.5
		_p(a, cell, _at(c, yaw, Vector3(sx, 0.42, -0.06)), Vector3((w - 0.4) * 0.5 - 0.02, 0.15, 0.68), mat, yaw, false)
	_p(a, cell, _at(c, yaw, Vector3(0, 0.62, 0.33)), Vector3(w - 0.4, 0.5, 0.2), mat, yaw, false)   # back
	for sx in [-1.0, 1.0]:                                                   # arms
		_p(a, cell, _at(c, yaw, Vector3(sx * (w * 0.5 - 0.1), 0.38, 0)), Vector3(0.2, 0.42, 0.9), mat, yaw, false)
	a.blob_shadow(cell, c, w + 0.4, 1.3)


static func _bed(a: Apartment, cell: String, c: Vector3, yaw: float, w: float, l: float, sheets := "sheet", cover := "cloth_grey") -> void:
	var bed_model := "bed_1_4x2_1" if absf(w - 1.4) < 0.01 else "bed_0_95x2"
	if a.place_model(bed_model, cell, _at(c, yaw, Vector3.ZERO), yaw):          # the model has its head at +Z, like the game's bed
		a.collider(_at(c, yaw, Vector3(0, 0.3, 0)), Vector3(w + 0.1, 0.6, l + 0.08), yaw)
		a.collider(_at(c, yaw, Vector3(0, 0.48, l * 0.5 + 0.03)), Vector3(w + 0.14, 0.95, 0.07), yaw)
		a.blob_shadow(cell, c, w + 0.5, l + 0.5)
		return
	_p(a, cell, _at(c, yaw, Vector3(0, 0.17, 0)), Vector3(w + 0.1, 0.3, l + 0.08), "dark_wood", yaw)
	_p(a, cell, _at(c, yaw, Vector3(0, 0.4, 0)), Vector3(w, 0.2, l), sheets, yaw, false)
	_p(a, cell, _at(c, yaw, Vector3(0.04, 0.52, -l * 0.17)), Vector3(w - 0.08, 0.1, l * 0.62), cover, yaw, false)    # duvet, pushed back
	_p(a, cell, _at(c, yaw, Vector3(-0.1, 0.56, -l * 0.46)), Vector3(w - 0.3, 0.08, 0.2), cover, yaw + 0.15, false)  # kicked-off fold
	for sx in ([-0.25, 0.25] if w > 1.2 else [0.0]):                         # pillows
		_p(a, cell, _at(c, yaw, Vector3(sx * w, 0.56, l * 0.4)), Vector3(0.5 if w > 1.2 else 0.45, 0.12, 0.34), "sheet", yaw + 0.05 * sx, false)
	_p(a, cell, _at(c, yaw, Vector3(0, 0.6, l * 0.5 + 0.03)), Vector3(w + 0.14, 0.9, 0.07), "dark_wood", yaw)         # headboard
	a.blob_shadow(cell, c, w + 0.5, l + 0.5)


static func _picture(a: Apartment, cell: String, wall_pos: Vector3, facing: Vector3, w: float, h: float, tone := "paper") -> void:
	var along_x := facing.x != 0.0
	if not a.hang_ok("picture at %s" % wall_pos, wall_pos, "x" if along_x else "z", w * 0.5, wall_pos.y - h * 0.5, wall_pos.y + h * 0.5):
		return                                                  # never hang anything on a door, an arch or a window
	var c := wall_pos + facing * 0.017
	var frame := Vector3(0.03, h, w) if along_x else Vector3(w, h, 0.03)
	var inner := Vector3(0.034, h - 0.08, w - 0.08) if along_x else Vector3(w - 0.08, h - 0.08, 0.034)
	_p(a, cell, c, frame, "dark_wood", 0.0, false)
	_p(a, cell, c + facing * 0.002, inner, tone, 0.0, false)


static func _books(a: Apartment, cell: String, start: Vector3, step: Vector3, count: int, h: float, d: float, seed_i := 0) -> void:
	var mats := ["cloth_red", "cloth_blue", "paper", "leather", "cloth_grey", "green_glass"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 100 + seed_i
	var pos := start
	for i in count:
		var th := rng.randf_range(0.025, 0.05)
		var hh := h * rng.randf_range(0.8, 1.0)
		var m: String = mats[rng.randi() % mats.size()]
		var along_x := absf(step.x) > absf(step.z)
		var size := Vector3(th, hh, d) if along_x else Vector3(d, hh, th)
		_p(a, cell, pos + Vector3(0, hh * 0.5, 0), size, m, 0.0, false)
		pos += step.normalized() * (th + 0.003)


static func _plant(a: Apartment, cell: String, c: Vector3, dead := true) -> void:
	a.cyl(c + Vector3(0, 0.15, 0), 0.14, 0.3, "cardboard", a.layer_of(cell), 0.11)
	for i in 5:
		var ang := float(i) * 1.26
		var tip := Vector3(cos(ang) * 0.16, 0.0, sin(ang) * 0.16)
		a.prop(cell, c + Vector3(tip.x * 0.5, 0.5, tip.z * 0.5), Vector3(0.015, 0.45, 0.015), "leather" if dead else "green_glass", ang, false)
		a.prop(cell, c + Vector3(tip.x, 0.7 - float(i % 2) * 0.1, tip.z), Vector3(0.06, 0.005, 0.1), "paper" if dead else "green_glass", ang, false)


static func _floor_lamp(a: Apartment, cell: String, c: Vector3, color := Color(1.0, 0.72, 0.45), energy := 0.45) -> void:
	var layer := a.layer_of(cell)
	a.place_model("floor_lamp", cell, c, 0.0)
	a.collider(c + Vector3(0, 0.85, 0), Vector3(0.36, 1.7, 0.36))                                    # you cannot walk into a lamp
	var light := OmniLight3D.new()
	light.position = c + Vector3(0, 1.5, 0)
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 3.0
	light.omni_attenuation = 1.4
	light.light_cull_mask = layer | Apartment.L_JAMB
	a.add_child(light)
	var bulb := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.04
	s.height = 0.08
	s.radial_segments = 8
	s.rings = 4
	bulb.mesh = s
	bulb.material_override = Mats.glow(color.lerp(Color.WHITE, 0.5))
	bulb.position = light.position
	bulb.layers = layer
	a.add_child(bulb)
	if not a.lamps.has(cell + "_floor"):
		a.lamps[cell + "_floor"] = []
	(a.lamps[cell + "_floor"] as Array).append({"light": light, "bulb": bulb, "energy": energy})


static func _rug(a: Apartment, cell: String, c: Vector3, w: float, d: float, mat := "cloth_red", yaw := 0.0) -> void:
	_p(a, cell, _at(c, yaw, Vector3(0, 0.006, 0)), Vector3(w, 0.012, d), mat, yaw, false)
	_p(a, cell, _at(c, yaw, Vector3(0, 0.0125, 0)), Vector3(w - 0.12, 0.002, d - 0.12), "cloth_grey", yaw, false)


static func _boxes(a: Apartment, cell: String, c: Vector3, rows: int, cols: int, size: Vector3, mat := "cardboard") -> void:
	for r in rows:
		for k in cols:
			var jitter := Vector3(sin(float(r * 7 + k * 3)) * 0.02, 0, cos(float(r * 5 + k * 11)) * 0.02)
			_p(a, cell, c + Vector3(float(k) * (size.x + 0.01) + jitter.x, size.y * (0.5 + float(r)), jitter.z), size, mat, sin(float(r + k)) * 0.15)


static func _litter(a: Apartment, cell: String, c: Vector3, n: int, spread: float, seed_i: int) -> void:
	# Crumpled clothes, papers, cans: small flat boxes scattered on the floor.
	var rng := RandomNumberGenerator.new()
	rng.seed = 700 + seed_i
	var mats := ["cloth_grey", "cloth_blue", "paper", "cloth_red", "cloth_grey", "paper"]
	for i in n:
		var p := c + Vector3(rng.randf_range(-spread, spread), 0.0, rng.randf_range(-spread, spread))
		var m: String = mats[rng.randi() % mats.size()]
		var sz := Vector3(rng.randf_range(0.18, 0.42), rng.randf_range(0.02, 0.07), rng.randf_range(0.14, 0.34))
		_p(a, cell, p + Vector3(0, sz.y * 0.5, 0), sz, m, rng.randf_range(0.0, 3.1), false)


static func _bottles(a: Apartment, cell: String, c: Vector3, n: int, spread: Vector2, seed_i: int, standing_ratio := 0.5) -> void:
	# Empty beer bottles: some standing, some on their side.
	var rng := RandomNumberGenerator.new()
	rng.seed = 900 + seed_i
	var layer := a.layer_of(cell)
	for i in n:
		var p := c + Vector3(rng.randf_range(-spread.x, spread.x), 0.0, rng.randf_range(-spread.y, spread.y))
		if rng.randf() < standing_ratio:
			a.place_model("bottle", cell, p, rng.randf_range(0.0, 6.28))
		else:
			a.place_model("bottle", cell, p + Vector3(0, 0.034, 0), rng.randf_range(0.0, 6.28), Basis(Vector3.RIGHT, PI / 2.0))


static func _rotten_plate(a: Apartment, cell: String, c: Vector3, seed_i: int) -> void:
	# A plate of food that has been there for days: grey-green mould, black patches.
	var layer := a.layer_of(cell)
	a.place_model("plate", cell, c, 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 400 + seed_i
	for i in 5:
		var o := Vector3(rng.randf_range(-0.06, 0.06), 0.03 + rng.randf() * 0.02, rng.randf_range(-0.06, 0.06))
		a.cyl(c + o, rng.randf_range(0.025, 0.045), 0.03, ["mold", "rot", "food", "mold", "rot"][i], layer, -1.0, 8)
	_p(a, cell, c + Vector3(0.14, 0.02, -0.04), Vector3(0.015, 0.012, 0.16), "metal", 0.5, false)     # fork


# --- rooms ---------------------------------------------------------------------------------

static func _entry(a: Apartment) -> void:
	var c := "entry"                                      # x[-0.94,1.14] z[-2.14,-0.11]
	_p(a, c, Vector3(-0.78, 0.17, -1.7), Vector3(0.3, 0.34, 0.8), "dark_wood")                       # shoe rack
	for i in 3:
		a.place_model("shoes", c, Vector3(-0.78, 0.34, -2.0 + float(i) * 0.26), float(i) * 0.6 + 1.5)
	_p(a, c, Vector3(-0.9, 1.55, -1.1), Vector3(0.04, 0.04, 0.5), "brass", 0.0, false)               # hooks
	a.hang_ok("coat on its hook", Vector3(-0.84, 1.0, -1.1), "x", 0.15, 0.4, 1.6)
	a.make_movable("coat", c, Vector3(-0.84, 1.0, -1.1), [[Vector3.ZERO, Vector3(0.1, 1.1, 0.3), "cloth_red"], [Vector3(0, 0.5, 0.0), Vector3(0.12, 0.08, 0.2), "cloth_red"]])   # Martin's red coat
	_p(a, c, Vector3(0.1, 0.007, -0.32), Vector3(0.8, 0.014, 0.45), "cloth_grey", 0.0, false)        # doormat
	for i in 7:                                                                                     # the mail, piled up by the door
		_p(a, c, Vector3(0.55 + float(i % 3) * 0.08, 0.012 + float(i) * 0.006, -0.55 + sin(float(i)) * 0.07), Vector3(0.22, 0.004, 0.14), "paper", float(i) * 0.7, false)
	a.use_point("mail", "Read the mail", Vector3(0.7, 0.4, 0.7), Vector3(0.6, 0.2, -0.55))
	_picture(a, c, Vector3(-0.94, 1.5, -1.7), Vector3(1, 0, 0), 0.5, 0.65, "glass")                  # a dark mirror
	a.use_point("mirror_entry", "The mirror", Vector3(0.4, 0.8, 0.7), Vector3(-0.78, 1.5, -1.7))
	a.stain(c, Vector3(0.1, 2.49, -1.4), Vector3(0, -1, 0), 1.0)
	a.stain(c, Vector3(1.14, 0.9, -0.4), Vector3(-1, 0, 0), 0.7, 1.4)
	_litter(a, c, Vector3(0.2, 0, -1.4), 3, 0.4, 1)


static func _kitchen(a: Apartment) -> void:
	var c := "kitchen"                                    # x[1.26,4.89] z[-2.14,-0.11]
	var layer := a.layer_of(c)
	a.place_model("fridge", c, Vector3(4.55, 0.0, -0.45), 0.0)                                       # fridge
	a.collider(Vector3(4.55, 0.9, -0.45), Vector3(0.65, 1.8, 0.65))
	a.place_model("cab_1_2_stove", c, Vector3(2.0, 0.0, -0.41), 0.0)                                  # stove unit, sink unit, base unit
	a.place_model("cab_1_0_sink", c, Vector3(3.1, 0.0, -0.41), 0.0)
	a.place_model("cab_0_6", c, Vector3(3.9, 0.0, -0.41), 0.0)
	a.collider(Vector3(2.0, 0.45, -0.41), Vector3(1.2, 0.9, 0.6))
	a.collider(Vector3(3.1, 0.45, -0.41), Vector3(1.0, 0.9, 0.6))
	a.collider(Vector3(3.9, 0.45, -0.41), Vector3(0.6, 0.9, 0.6))
	_p(a, c, Vector3(2.0, 1.65, -0.27), Vector3(1.2, 0.7, 0.32), "dark_wood", 0.0, false)            # wall cupboards
	_p(a, c, Vector3(3.9, 1.65, -0.27), Vector3(0.6, 0.7, 0.32), "dark_wood", 0.0, false)
	# Rotten food: a pot on the stove, plates in the sink, a pizza box on the counter
	a.cyl(Vector3(1.75, 1.0, -0.28), 0.13, 0.16, "metal", layer, -1.0, 12)
	a.cyl(Vector3(1.75, 1.09, -0.28), 0.115, 0.02, "mold", layer, -1.0, 12)
	for i in 5:
		a.cyl(Vector3(3.0 + float(i % 2) * 0.1, 0.95 + float(i) * 0.035, -0.45), 0.1, 0.03, "white", layer, -1.0, 10)
	_rotten_plate(a, c, Vector3(3.1, 1.12, -0.45), 1)
	a.place_model("pizza_box", c, Vector3(2.55, 0.92, -0.4), 0.2)                                    # pizza box
	_bottles(a, c, Vector3(3.9, 0.92, -0.4), 4, Vector2(0.2, 0.1), 21, 0.7)
	# The trash corner (north-east): an overflowing bin, torn bags and spilled rubbish, empty beer bottles
	a.cyl(Vector3(4.62, 0.32, -1.85), 0.2, 0.64, "black", layer, 0.22, 12)
	a.place_model("bag_0", c, Vector3(4.62, 0.58, -1.85), 0.4)                                        # overflow on the bin
	a.place_model("bag_1", c, Vector3(4.2, 0.0, -2.0), 1.1)
	a.place_model("bag_2", c, Vector3(4.42, 0.0, -1.5), 2.3)
	a.place_model("bag_0", c, Vector3(4.12, 0.0, -1.62), 0.2)
	a.place_model("bag_1", c, Vector3(4.78, 0.0, -1.2), 3.0)
	for i in 9:                                                                                       # spilled rubbish
		var mats := ["paper", "food", "cloth_red", "rot", "mold", "paper", "cloth_blue", "food", "paper"]
		_p(a, c, Vector3(4.0 + float(i % 4) * 0.2, 0.012, -1.35 - float(i / 4) * 0.22), Vector3(0.11 + 0.03 * float(i % 3), 0.02, 0.08 + 0.03 * float(i % 2)), mats[i], float(i) * 0.9, false)
	_bottles(a, c, Vector3(4.5, 0.0, -1.55), 18, Vector2(0.45, 0.6), 22, 0.45)
	_rotten_plate(a, c, Vector3(4.35, 0.0, -1.0), 2)
	_litter(a, c, Vector3(3.6, 0, -1.4), 4, 0.5, 6)
	a.stain(c, Vector3(3.0, 2.49, -1.2), Vector3(0, -1, 0), 1.6)
	a.stain(c, Vector3(3.0, 1.5, -0.11), Vector3(0, 0, -1), 1.0, 1.4)
	a.stain(c, Vector3(4.89, 0.5, -1.7), Vector3(-1, 0, 0), 0.9, 1.0)
	_picture(a, c, Vector3(2.0, 1.5, -2.14), Vector3(0, 0, 1), 0.34, 0.45, "paper")                   # the calendar
	a.use_point("calendar", "The calendar", Vector3(0.6, 0.7, 0.5), Vector3(2.0, 1.5, -2.0))
	a.use_point("fridge", "Open the fridge", Vector3(0.8, 1.8, 0.8), Vector3(4.55, 0.9, -0.45))
	a.use_point("trash", "The trash", Vector3(0.8, 0.8, 0.9), Vector3(4.5, 0.4, -1.7))
	a.use_point("kitchen_food", "Look at the food", Vector3(0.9, 0.5, 0.6), Vector3(2.8, 1.0, -0.4))
	a.add_flies(c, Vector3(4.55, 0.75, -1.75), 18, 0.34)
	a.add_flies(c, Vector3(2.9, 1.25, -0.5), 12, 0.26)


static func _living(a: Apartment) -> void:
	var c := "living"                                     # x[-0.94,4.89] z[-8.89,-2.14]
	var layer := a.layer_of(c)
	_p(a, c, Vector3(1.0, 0.225, -9.25), Vector3(1.5, 0.45, 0.42), "dark_wood")                      # TV stand
	a.place_model("tv", c, Vector3(1.0, 0.45, -9.27), PI)                                            # TV on its stand
	a.use_point("tv", "Turn on the TV", Vector3(1.1, 0.8, 0.5), Vector3(1.25, 0.85, -9.2))
	a.setup_tv(Vector3(1.0, 0.83, -9.236), 1.07, 0.6)
	# He is on the sofa, in the epilogue only: slumped, facing the TV, in the grey hoodie and jeans
	a.make_movable("body", c, Vector3(1.0, 0.0, -6.4), [
		[Vector3(0, 0.78, 0.12), Vector3(0.5, 0.56, 0.3), "cloth_grey"],
		[Vector3(-0.12, 0.56, -0.28), Vector3(0.15, 0.16, 0.6), "cloth_blue"],
		[Vector3(0.12, 0.56, -0.28), Vector3(0.15, 0.16, 0.6), "cloth_blue"],
		[Vector3(-0.3, 0.7, -0.05), Vector3(0.09, 0.09, 0.4), "cloth_grey"],
		[Vector3(0.3, 0.7, -0.05), Vector3(0.09, 0.09, 0.4), "cloth_grey"],
		[Vector3(0.02, 1.2, 0.15), Vector3(0.12, 0.12, 0.12), "skin", "sphere"]], 0.0, false)
	_sofa(a, c, Vector3(1.0, 0, -6.5), 0.0, 2.1)
	_p(a, c, Vector3(0.5, 0.6, -6.4), Vector3(0.9, 0.1, 0.6), "cloth_grey", 0.3, false)              # blanket thrown on the sofa
	_p(a, c, Vector3(1.5, 0.6, -6.55), Vector3(0.4, 0.16, 0.3), "cloth_blue", -0.4, false)           # a jacket
	a.use_point("sofa", "Sit down", Vector3(2.0, 0.9, 1.0), Vector3(1.0, 0.45, -6.5))
	_table(a, c, Vector3(1.0, 0, -7.9), 1.0, 0.55, 0.42, "dark_wood")                               # coffee table, strewn
	a.place_model("pizza_box", c, Vector3(0.75, 0.42, -7.9), 0.6)                                    # pizza box
	_rotten_plate(a, c, Vector3(1.25, 0.43, -7.85), 3)
	_bottles(a, c, Vector3(1.0, 0.43, -7.9), 3, Vector2(0.3, 0.1), 31, 0.6)
	_rug(a, c, Vector3(1.0, 0, -7.6), 2.4, 1.8, "cloth_blue")
	a.place_model("bookshelf", c, Vector3(-0.78, 0.0, -8.6), -PI / 2.0)                             # bookshelf, books facing east
	a.collider(Vector3(-0.78, 0.95, -8.6), Vector3(0.3, 1.9, 1.1))
	_table(a, c, Vector3(3.4, 0, -9.15), 1.3, 0.6, 0.74, "dark_wood")                                # desk under the north window
	_chair(a, c, Vector3(3.4, 0, -8.55), 0.0)
	a.place_model("laptop", c, Vector3(3.3, 0.74, -9.15), PI)                                        # laptop
	for i in 6:
		_p(a, c, Vector3(3.75 + float(i % 3) * 0.04, 0.77 + float(i) * 0.008, -9.1), Vector3(0.22, 0.008, 0.3), "paper", float(i) * 0.5, false)   # job applications
	a.use_point("laptop", "Use the laptop", Vector3(0.9, 0.5, 0.7), Vector3(3.4, 0.9, -9.1))
	# Dining table by the east windows, with food that has been left to rot
	_table(a, c, Vector3(3.9, 0, -5.6), 0.9, 1.5, 0.75, "dark_wood")
	_chair(a, c, Vector3(3.1, 0, -5.1), -PI / 2.0)
	_chair(a, c, Vector3(3.1, 0, -6.1), -PI / 2.0)
	_p(a, c, Vector3(4.6, 0.12, -6.7), Vector3(0.42, 0.42, 0.42), "dark_wood", 0.7, false)           # a chair knocked over
	_rotten_plate(a, c, Vector3(3.7, 0.76, -5.0), 4)
	_rotten_plate(a, c, Vector3(3.7, 0.76, -6.0), 5)
	_rotten_plate(a, c, Vector3(4.1, 0.76, -5.5), 6)
	a.cyl(Vector3(3.9, 0.84, -5.55), 0.09, 0.16, "metal", layer, -1.0, 10)                            # a pot with a skin of mould
	a.cyl(Vector3(3.9, 0.925, -5.55), 0.08, 0.02, "mold", layer, -1.0, 10)
	_bottles(a, c, Vector3(4.0, 0.75, -5.5), 5, Vector2(0.3, 0.6), 32, 0.7)
	a.use_point("dining_food", "Look at the table", Vector3(0.6, 0.5, 1.6), Vector3(3.7, 0.9, -5.5))
	a.add_flies(c, Vector3(3.9, 1.0, -5.5), 22, 0.4)
	a.add_flies(c, Vector3(1.2, 0.8, -7.4), 8, 0.22)
	_floor_lamp(a, c, Vector3(2.4, 0, -6.9))
	_picture(a, c, Vector3(4.89, 1.7, -3.7), Vector3(-1, 0, 0), 0.5, 0.4, "paper")
	_p(a, c, Vector3(0.45, 0.5, -9.22), Vector3(0.18, 0.22, 0.03), "dark_wood", 0.0, false)          # the framed photo of Mom and Dad
	_p(a, c, Vector3(0.45, 0.5, -9.2), Vector3(0.14, 0.18, 0.034), "paper", 0.0, false)
	a.use_point("photo_parents", "Look at the photo", Vector3(0.4, 0.4, 0.4), Vector3(0.45, 0.5, -9.2))
	_p(a, c, Vector3(-0.92, 1.95, -7.0), Vector3(0.04, 0.34, 0.34), "white", 0.0, false)             # wall clock
	_p(a, c, Vector3(-0.895, 1.95, -7.0), Vector3(0.012, 0.012, 0.13), "black", 0.0, false)
	_p(a, c, Vector3(-0.895, 1.99, -6.95), Vector3(0.012, 0.1, 0.012), "black", 0.0, false)
	a.use_point("clock", "The clock", Vector3(0.4, 0.6, 0.6), Vector3(-0.85, 1.95, -7.0))
	a.use_point("window_living", "Look outside", Vector3(0.4, 1.3, 1.4), Vector3(4.8, 1.5, -8.4))
	_bottles(a, c, Vector3(2.5, 0, -4.0), 6, Vector2(0.9, 0.5), 33, 0.4)
	_litter(a, c, Vector3(1.8, 0, -4.2), 9, 1.2, 7)
	a.stain(c, Vector3(4.0, 2.49, -5.5), Vector3(0, -1, 0), 1.8)
	a.stain(c, Vector3(0.5, 2.49, -3.5), Vector3(0, -1, 0), 1.3)
	a.stain(c, Vector3(4.89, 0.7, -7.2), Vector3(-1, 0, 0), 1.0, 1.5)


static func _hall(a: Apartment) -> void:
	var c := "hall"                                       # x[-6.29,-1.06] z[-5.54,-4.26]
	_p(a, c, Vector3(-6.05, 0.37, -4.9), Vector3(0.4, 0.74, 0.6), "dark_wood")                       # phone table
	a.place_model("phone", c, Vector3(-6.05, 0.74, -4.9), -PI / 2.0)                                 # phone and answering machine
	a.use_point("phone", "The phone", Vector3(0.6, 0.6, 0.8), Vector3(-6.0, 0.8, -4.9))
	_rug(a, c, Vector3(-3.6, 0, -4.9), 3.4, 0.8, "cloth_red")
	_picture(a, c, Vector3(-3.05, 1.5, -5.54), Vector3(0, 0, 1), 0.5, 0.35, "cloth_blue")
	_picture(a, c, Vector3(-4.05, 1.5, -5.54), Vector3(0, 0, 1), 0.36, 0.5, "paper")
	_picture(a, c, Vector3(-3.7, 1.5, -4.26), Vector3(0, 0, -1), 0.6, 0.4, "cloth_red")
	_plant(a, c, Vector3(-1.5, 0.0, -4.5))
	a.stain(c, Vector3(-4.5, 2.49, -4.9), Vector3(0, -1, 0), 1.1)
	a.stain(c, Vector3(-6.29, 0.5, -5.2), Vector3(1, 0, 0), 0.9, 1.2)


static func _bath(a: Apartment) -> void:
	var c := "bath"                                       # x[-6.29,-3.86] z[-4.14,-1.71]
	a.place_model("tub", c, Vector3(-5.44, 0.0, -2.085), PI)                                         # tub (taps toward the room's east end)
	a.collider(Vector3(-5.44, 0.28, -2.085), Vector3(1.7, 0.56, 0.75))
	_p(a, c, Vector3(-5.44, 1.3, -2.5), Vector3(1.55, 1.7, 0.02), "sheet", 0.0, false)               # shower curtain, drawn
	a.cyl(Vector3(-5.44, 2.15, -2.5), 0.012, 1.6, "chrome", a.layer_of(c), -1.0, 6)
	a.place_model("toilet", c, Vector3(-5.9, 0.0, -3.2), -PI / 2.0)                                  # toilet, facing east
	a.collider(Vector3(-5.98, 0.3, -3.2), Vector3(0.5, 0.6, 0.38))
	a.place_model("sink", c, Vector3(-4.1, 0.0, -3.6), PI / 2.0)                                     # basin on its pedestal, facing west
	a.collider(Vector3(-4.05, 0.45, -3.6), Vector3(0.4, 0.9, 0.5))
	_p(a, c, Vector3(-3.92, 1.58, -3.6), Vector3(0.1, 0.8, 0.55), "dark_wood", 0.0, false)           # medicine cabinet
	_p(a, c, Vector3(-3.87, 1.58, -3.6), Vector3(0.03, 0.72, 0.47), "glass", 0.0, false)
	a.use_point("pills", "The medicine cabinet", Vector3(0.5, 0.9, 0.7), Vector3(-3.95, 1.5, -3.6))
	a.use_point("shower", "Take a shower", Vector3(1.8, 1.2, 0.9), Vector3(-5.44, 0.7, -2.35))
	_p(a, c, Vector3(-4.7, 0.012, -3.2), Vector3(0.5, 0.02, 0.8), "cloth_blue", 0.0, false)         # bath mat
	_p(a, c, Vector3(-6.25, 1.2, -2.2), Vector3(0.04, 0.5, 0.3), "cloth_grey", 0.0, false)          # towel
	a.stain(c, Vector3(-5.2, 2.49, -2.5), Vector3(0, -1, 0), 1.5)
	a.stain(c, Vector3(-5.6, 1.8, -1.71), Vector3(0, 0, -1), 1.0, 1.4)
	a.stain(c, Vector3(-4.4, 0.8, -4.14), Vector3(0, 0, 1), 0.8, 1.6)
	a.blob_shadow(c, Vector3(-5.44, 0, -2.085), 2.0, 1.1)


static func _storage(a: Apartment) -> void:
	var c := "storage"                                    # x[-3.74,-1.06] z[-4.14,-1.71]
	_boxes(a, c, Vector3(-3.5, 0, -3.8), 3, 1, Vector3(0.45, 0.34, 0.4))
	_boxes(a, c, Vector3(-3.5, 0, -3.2), 2, 1, Vector3(0.45, 0.4, 0.45))
	_boxes(a, c, Vector3(-3.5, 0, -2.5), 3, 1, Vector3(0.45, 0.32, 0.4))
	_boxes(a, c, Vector3(-3.0, 0, -1.95), 2, 3, Vector3(0.4, 0.3, 0.34))
	a.use_point("dad_boxes", "Dad's things", Vector3(0.9, 1.1, 2.2), Vector3(-3.5, 0.5, -3.0))
	a.place_model("armchair", c, Vector3(-1.45, 0.0, -2.2), 0.7)                                      # his armchair
	a.collider(Vector3(-1.45, 0.4, -2.2), Vector3(0.9, 0.8, 0.85), 0.7)
	a.blob_shadow(c, Vector3(-1.45, 0, -2.2), 1.3, 1.3)
	_p(a, c, Vector3(-3.5, 1.1, -3.0), Vector3(0.3, 0.18, 0.12), "black", 0.3, false)                # his radio, on the boxes
	_picture(a, c, Vector3(-1.06, 1.55, -2.9), Vector3(-1, 0, 0), 0.5, 0.4, "paper")                 # family photo
	_picture(a, c, Vector3(-3.74, 1.5, -2.9), Vector3(1, 0, 0), 0.4, 0.5, "cloth_blue")
	_litter(a, c, Vector3(-2.4, 0, -3.0), 4, 0.4, 1)
	a.stain(c, Vector3(-2.8, 2.49, -3.0), Vector3(0, -1, 0), 1.2)


static func _bed1(a: Apartment) -> void:
	var c := "bed1"                                       # x[-6.29,-3.46] z[-8.89,-5.66]
	_bed(a, c, Vector3(-4.85, 0, -8.41), PI, 1.4, 2.1)                                               # head to the north wall
	a.use_point("bed1", "Go to sleep", Vector3(1.4, 0.9, 2.0), Vector3(-4.85, 0.5, -8.2))
	_p(a, c, Vector3(-3.75, 0.25, -9.2), Vector3(0.4, 0.5, 0.4), "dark_wood")
	a.cyl(Vector3(-3.75, 0.62, -9.2), 0.05, 0.2, "brass", a.layer_of(c), 0.03, 8)                     # bedside lamp
	a.cyl(Vector3(-3.75, 0.82, -9.2), 0.1, 0.16, "lampshade", a.layer_of(c), 0.07, 10)
	_bottles(a, c, Vector3(-3.75, 0.5, -8.9), 2, Vector2(0.05, 0.1), 41, 1.0)
	a.place_model("wardrobe_1_2x0_6", c, Vector3(-5.99, 0.0, -6.4), -PI / 2.0)                        # wardrobe, doors facing east
	a.collider(Vector3(-5.99, 1.0, -6.4), Vector3(0.6, 2.0, 1.2))
	a.use_point("wardrobe", "The wardrobe", Vector3(0.8, 2.0, 1.4), Vector3(-5.95, 1.0, -6.4))
	_rug(a, c, Vector3(-4.85, 0, -6.4), 1.8, 1.1, "cloth_blue")
	_litter(a, c, Vector3(-4.6, 0, -6.2), 8, 0.7, 2)
	_bottles(a, c, Vector3(-5.1, 0, -6.1), 4, Vector2(0.6, 0.3), 42, 0.5)
	_picture(a, c, Vector3(-3.46, 1.6, -7.8), Vector3(-1, 0, 0), 0.6, 0.45, "cloth_grey")
	a.stain(c, Vector3(-4.6, 2.49, -7.5), Vector3(0, -1, 0), 1.3)
	a.stain(c, Vector3(-6.29, 2.0, -7.5), Vector3(1, 0, 0), 0.9, 1.0)


static func _bed2(a: Apartment) -> void:
	var c := "bed2"                                       # x[-3.34,-1.06] z[-8.89,-5.66]
	_bed(a, c, Vector3(-1.55, 0, -8.46), PI, 0.95, 2.0, "sheet", "cloth_blue")                         # Jack's old bed
	_table(a, c, Vector3(-3.04, 0, -8.0), 0.6, 1.2, 0.74, "dark_wood")                                # desk
	_chair(a, c, Vector3(-2.7, 0, -8.0), PI / 2.0)
	_p(a, c, Vector3(-3.05, 0.92, -8.3), Vector3(0.35, 0.3, 0.3), "black", 0.0, false)               # old monitor
	_p(a, c, Vector3(-3.0, 0.78, -7.7), Vector3(0.3, 0.02, 0.2), "paper", 0.0, false)
	a.use_point("jack_desk", "Jack's desk", Vector3(0.8, 0.8, 1.4), Vector3(-3.0, 0.8, -8.0))
	_p(a, c, Vector3(-2.4, 1.0, -9.48), Vector3(0.9, 0.02, 0.28), "dark_wood", 0.0, false)            # shelf with trophies
	for i in 4:
		a.cyl(Vector3(-2.7 + float(i) * 0.22, 1.1, -9.4), 0.045, 0.15, "brass", a.layer_of(c), 0.03, 8)
	_picture(a, c, Vector3(-3.34, 1.6, -8.8), Vector3(1, 0, 0), 0.5, 0.7, "cloth_red")                # poster
	_litter(a, c, Vector3(-2.3, 0, -6.3), 3, 0.4, 4)
	a.stain(c, Vector3(-2.2, 2.49, -7.5), Vector3(0, -1, 0), 1.4)


## The things that are out of place on particular days (see Days.ANOMALY). All hidden until a day asks for them;
## none has a collider, so they sit along walls and never in the way.
static func _anomalies(a: Apartment) -> void:
	# a dining chair outside his bedroom door, facing it
	var chair: Array = []
	var cm := "dark_wood"
	chair.append([Vector3(0, 0.45, 0), Vector3(0.42, 0.04, 0.42), cm])
	chair.append([Vector3(0, 0.72, 0.19), Vector3(0.42, 0.5, 0.04), cm])
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			chair.append([Vector3(sx * 0.18, 0.22, sz * 0.18), Vector3(0.04, 0.44, 0.04), cm])
	a.make_movable("hall_chair", "hall", Vector3(-4.9, 0.0, -4.5), chair, 0.0, false)
	# grey bare footprints from his bedroom door, down the hall, to the living room
	var prints: Array = []
	var path := [Vector3(-4.9, 0, -5.45), Vector3(-4.9, 0, -4.9), Vector3(-1.0, 0, -4.9), Vector3(0.1, 0, -5.8), Vector3(0.15, 0, -7.35)]
	var side := 1.0
	for i in path.size() - 1:
		var from: Vector3 = path[i]
		var to: Vector3 = path[i + 1]
		var dir := (to - from)
		var length := dir.length()
		var n := int(length / 0.55)
		for k in n:
			var p := from + dir * ((float(k) + 0.5) / float(n))
			var along_x := absf(dir.x) > absf(dir.z)
			var off := Vector3(0, 0, side * 0.09) if along_x else Vector3(side * 0.09, 0, 0)
			var fwd := dir.normalized()
			var q := p + off + Vector3(0, 0.008, 0)
			var ball := Vector3(0.1, 0.006, 0.12) if along_x else Vector3(0.12, 0.006, 0.1)
			var heel := Vector3(0.07, 0.006, 0.07)
			prints.append([q + fwd * 0.07, ball, "paper"])                    # the ball of the foot
			prints.append([q - fwd * 0.1, heel, "paper"])                     # the heel, with a gap of bare floor between
			side = -side
	a.make_movable("prints", "hall", Vector3.ZERO, prints, 0.0, false)
	# his coat on the floor inside the front door
	a.make_movable("coat_floor", "entry", Vector3(0.15, 0.0, -0.45), [
		[Vector3(0, 0.05, 0), Vector3(0.62, 0.1, 0.42), "cloth_red"], [Vector3(0.28, 0.04, 0.2), Vector3(0.5, 0.08, 0.14), "cloth_red"],
		[Vector3(-0.22, 0.04, 0.24), Vector3(0.1, 0.07, 0.5), "cloth_red"]], 0.3, false)
	# Dad's boxes, opened and spilled across the storage room floor
	var boxes: Array = []
	for i in 7:
		boxes.append([Vector3(sin(float(i) * 2.1) * 0.5, 0.1 + float(i % 2) * 0.1, cos(float(i) * 1.7) * 0.4), Vector3(0.34 + 0.06 * float(i % 3), 0.2, 0.3), "cardboard"])
		boxes.append([Vector3(sin(float(i) * 1.3 + 1.0) * 0.7, 0.012, cos(float(i) * 2.3) * 0.55), Vector3(0.24, 0.012, 0.32), "paper"])
	a.make_movable("boxes_out", "storage", Vector3(-2.45, 0.0, -3.0), boxes, 0.0, false)
	# the tub has run over: a wide dark pool of water on the tiles
	a.make_movable("tub_water", "bath", Vector3(-4.8, 0.0, -2.75), [
		[Vector3(0, 0.007, 0), Vector3(1.9, 0.01, 1.1), "black"], [Vector3(0.6, 0.007, 0.3), Vector3(0.9, 0.01, 0.8), "black"]], 0.0, false)
	# his coat, folded, on Jack's bed
	a.make_movable("coat_bed", "bed2", Vector3(-1.55, 0.0, -7.9), [
		[Vector3(0, 0.6, 0), Vector3(0.5, 0.12, 0.7), "cloth_red"], [Vector3(0, 0.67, 0.1), Vector3(0.44, 0.05, 0.3), "cloth_red"]], 0.0, false)
	# the dining table set for two: clean white plates, cups, and a note
	a.make_movable("table_set", "living", Vector3(3.9, 0.0, -5.5), [
		[Vector3(-0.25, 0.775, -0.2), Vector3(0.26, 0.025, 0.26), "white"], [Vector3(-0.25, 0.775, 0.22), Vector3(0.26, 0.025, 0.26), "white"],
		[Vector3(-0.05, 0.81, -0.2), Vector3(0.09, 0.09, 0.09), "white"], [Vector3(-0.05, 0.81, 0.22), Vector3(0.09, 0.09, 0.09), "white"],
		[Vector3(0.25, 0.763, 0.0), Vector3(0.2, 0.003, 0.28), "paper"]], 0.0, false)
	a.use_point("note", "Pick up the note", Vector3(0.4, 0.4, 0.5), Vector3(4.2, 0.8, -5.5))
	a.set_use("note", false)


static func _spots(a: Apartment) -> void:
	a.stranger_spots = [
		Vector3(-5.5, 0, -4.9), Vector3(-3.4, 0, -4.9), Vector3(-1.7, 0, -4.9),
		Vector3(-0.2, 0, -4.4), Vector3(0.1, 0, -3.3), Vector3(2.4, 0, -3.4), Vector3(4.2, 0, -3.1),
		Vector3(4.3, 0, -8.2), Vector3(2.4, 0, -8.3), Vector3(0.0, 0, -7.6), Vector3(2.4, 0, -5.0),
		Vector3(2.4, 0, -1.4), Vector3(3.6, 0, -1.5),
		Vector3(-4.9, 0, -6.3), Vector3(-2.2, 0, -6.3), Vector3(-5.1, 0, -3.3), Vector3(-2.4, 0, -3.3)]
