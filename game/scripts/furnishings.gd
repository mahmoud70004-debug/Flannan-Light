class_name Furnishings
## Furniture, clutter and decay for every room of the flat. Everything is boxes, cylinders and
## soft stains, merged into the flat's batches. Coordinates are in metres. Local frames: a
## prop's front looks along local -Z; `yaw` turns it (yaw 0 faces north, PI/2 faces west).

static func furnish(a: Apartment) -> void:
	_hall_front(a)
	_hall_back(a)
	_hall_w(a)
	_bath(a)
	_dads(a)
	_bedroom(a)
	_dressing(a)
	_spare(a)
	_utility(a)
	_kitchen(a)
	_living(a)
	_box_room(a)
	_study(a)


# --- generic pieces --------------------------------------------------------------------

static func _at(c: Vector3, yaw: float, off: Vector3) -> Vector3:
	return c + Basis(Vector3.UP, yaw) * off


static func _p(a: Apartment, cell: String, c: Vector3, size: Vector3, mat: String, yaw := 0.0, collide := true) -> void:
	a.prop(cell, c, size, mat, yaw, collide)


static func _table(a: Apartment, cell: String, c: Vector3, w: float, d: float, h: float, mat: String, yaw := 0.0) -> void:
	_p(a, cell, _at(c, yaw, Vector3(0, h - 0.02, 0)), Vector3(w, 0.04, d), mat, yaw)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_p(a, cell, _at(c, yaw, Vector3(sx * (w * 0.5 - 0.04), (h - 0.04) * 0.5, sz * (d * 0.5 - 0.04))), Vector3(0.05, h - 0.04, 0.05), mat, yaw, false)
	a.blob_shadow(cell, c, w + 0.3, d + 0.3)


static func _chair(a: Apartment, cell: String, c: Vector3, yaw: float, mat := "dark_wood") -> void:
	_p(a, cell, _at(c, yaw, Vector3(0, 0.45, 0)), Vector3(0.42, 0.04, 0.42), mat, yaw)
	_p(a, cell, _at(c, yaw, Vector3(0, 0.72, 0.19)), Vector3(0.42, 0.5, 0.04), mat, yaw, false)
	_p(a, cell, _at(c, yaw, Vector3(0, 0.84, 0.19)), Vector3(0.34, 0.1, 0.05), mat, yaw, false)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_p(a, cell, _at(c, yaw, Vector3(sx * 0.18, 0.22, sz * 0.18)), Vector3(0.04, 0.44, 0.04), mat, yaw, false)
	a.blob_shadow(cell, c, 0.55, 0.55)


static func _sofa(a: Apartment, cell: String, c: Vector3, yaw: float, w: float, mat := "fabric") -> void:
	_p(a, cell, _at(c, yaw, Vector3(0, 0.2, 0)), Vector3(w, 0.3, 0.9), "dark_wood", yaw)
	for i in 2:                                                              # seat cushions
		var sx := (-0.5 + i) * (w - 0.4) * 0.5
		_p(a, cell, _at(c, yaw, Vector3(sx, 0.42, -0.06)), Vector3((w - 0.4) * 0.5 - 0.02, 0.15, 0.68), mat, yaw, false)
	_p(a, cell, _at(c, yaw, Vector3(0, 0.62, 0.33)), Vector3(w - 0.4, 0.5, 0.2), mat, yaw, false)   # back
	for sx in [-1.0, 1.0]:                                                   # arms
		_p(a, cell, _at(c, yaw, Vector3(sx * (w * 0.5 - 0.1), 0.38, 0)), Vector3(0.2, 0.42, 0.9), mat, yaw, false)
	a.blob_shadow(cell, c, w + 0.4, 1.3)


static func _bed(a: Apartment, cell: String, c: Vector3, yaw: float, w: float, l: float, sheets := "sheet", cover := "cloth_grey") -> void:
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
	a.cyl(c + Vector3(0, 0.02, 0), 0.15, 0.04, "metal", layer)
	a.cyl(c + Vector3(0, 0.8, 0), 0.015, 1.6, "metal", layer, -1.0, 6)
	a.cyl(c + Vector3(0, 1.62, 0), 0.07, 0.3, "lampshade", layer, 0.13)
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


# --- halls -----------------------------------------------------------------------------

static func _hall_front(a: Apartment) -> void:
	var c := "hall_front"
	_p(a, c, Vector3(-0.78, 0.17, -3.1), Vector3(0.3, 0.34, 0.8), "dark_wood")                      # shoe rack
	for i in 4:
		_p(a, c, Vector3(-0.78, 0.4, -3.35 + float(i) * 0.2), Vector3(0.22, 0.09, 0.13), "leather", float(i) * 0.4, false)
	_p(a, c, Vector3(0.29, 1.55, -3.4), Vector3(0.05, 0.04, 0.7), "brass", 0.0, false)             # hook rail
	_p(a, c, Vector3(0.24, 1.0, -3.65), Vector3(0.1, 1.15, 0.28), "cloth_grey", 0.0, false)         # coats
	_p(a, c, Vector3(0.24, 0.95, -3.25), Vector3(0.1, 1.05, 0.26), "cloth_blue", 0.0, false)
	_p(a, c, Vector3(-0.3, 0.007, -0.45), Vector3(0.7, 0.014, 0.45), "cloth_grey", 0.0, false)       # doormat
	for i in 6:                                                                                      # mail on the floor
		_p(a, c, Vector3(-0.45 + float(i) * 0.09, 0.012, -0.75 + sin(float(i)) * 0.1), Vector3(0.2, 0.004, 0.12), "paper", float(i) * 0.7, false)
	_picture(a, c, Vector3(-0.94, 1.55, -3.9), Vector3(1, 0, 0), 0.5, 0.65, "glass")                 # a dark mirror
	a.stain(c, Vector3(-0.3, 2.49, -3.0), Vector3(0, -1, 0), 1.0)
	a.stain(c, Vector3(0.335, 0.9, -2.0), Vector3(-1, 0, 0), 0.7, 1.4)


static func _hall_back(a: Apartment) -> void:
	var c := "hall_back"
	_p(a, c, Vector3(-0.3, 0.37, -9.65), Vector3(0.6, 0.74, 0.4), "dark_wood")                        # phone table
	_p(a, c, Vector3(-0.3, 0.77, -9.65), Vector3(0.26, 0.07, 0.2), "black", 0.0, false)             # landline body
	_p(a, c, Vector3(-0.3, 0.83, -9.65), Vector3(0.22, 0.04, 0.07), "black", 0.0, false)             # handset
	_p(a, c, Vector3(-0.3, 0.82, -9.62), Vector3(0.1, 0.012, 0.1), "paper", 0.0, false)
	_picture(a, c, Vector3(-0.94, 1.5, -6.0), Vector3(1, 0, 0), 0.4, 0.5, "cloth_blue")
	_picture(a, c, Vector3(-0.94, 1.5, -8.0), Vector3(1, 0, 0), 0.32, 0.42, "cloth_red")
	_picture(a, c, Vector3(0.34, 1.5, -7.0), Vector3(-1, 0, 0), 0.5, 0.36, "paper")
	_plant(a, c, Vector3(0.0, 0.0, -9.35))
	a.stain(c, Vector3(-0.3, 2.49, -7.8), Vector3(0, -1, 0), 1.3)
	a.stain(c, Vector3(-0.94, 0.5, -5.5), Vector3(1, 0, 0), 0.9, 1.2)


static func _hall_w(a: Apartment) -> void:
	var c := "hall_w"
	_rug(a, c, Vector3(-3.8, 0, -6.7), 3.6, 0.8, "cloth_red")
	_p(a, c, Vector3(-6.2, 0.4, -6.75), Vector3(0.3, 0.8, 0.6), "dark_wood")                          # small chest by the window
	_picture(a, c, Vector3(-2.2, 1.5, -6.06), Vector3(0, 0, 1), 0.5, 0.35, "cloth_blue")
	_picture(a, c, Vector3(-4.6, 1.5, -6.06), Vector3(0, 0, 1), 0.36, 0.5, "paper")
	_picture(a, c, Vector3(-3.4, 1.5, -7.34), Vector3(0, 0, -1), 0.6, 0.4, "cloth_red")
	a.stain(c, Vector3(-5.2, 2.49, -6.7), Vector3(0, -1, 0), 1.1)


# --- rooms ---------------------------------------------------------------------------------

static func _bath(a: Apartment) -> void:
	var c := "bath"
	var b := a.ib(c)                                     # x[-3.34,-1.06] z[-2.54,-0.11]
	_p(a, c, Vector3(-2.49, 0.28, -2.165), Vector3(1.7, 0.56, 0.75), "white")                       # tub
	_p(a, c, Vector3(-2.49, 0.57, -2.165), Vector3(1.55, 0.02, 0.6), "chrome", 0.0, false)
	_p(a, c, Vector3(-1.7, 0.75, -2.45), Vector3(0.04, 0.04, 0.12), "chrome", 0.0, false)           # taps
	_p(a, c, Vector3(-2.49, 1.2, -1.8), Vector3(1.55, 1.7, 0.02), "sheet", 0.0, false)              # shower curtain, drawn
	a.cyl(Vector3(-2.49, 2.05, -1.8), 0.012, 1.6, "chrome", a.layer_of(c), -1.0, 6)
	_p(a, c, Vector3(-2.2, 0.2, -0.42), Vector3(0.36, 0.4, 0.5), "white")                            # toilet
	_p(a, c, Vector3(-2.2, 0.62, -0.2), Vector3(0.4, 0.44, 0.18), "white", 0.0, false)
	_p(a, c, Vector3(-2.2, 0.43, -0.4), Vector3(0.38, 0.03, 0.44), "white", 0.0, false)
	_p(a, c, Vector3(-3.1, 0.82, -1.2), Vector3(0.4, 0.12, 0.5), "white")                            # basin
	_p(a, c, Vector3(-3.15, 0.4, -1.2), Vector3(0.12, 0.8, 0.12), "white", 0.0, false)
	_p(a, c, Vector3(-3.3, 1.5, -1.2), Vector3(0.03, 0.75, 0.52), "dark_wood", 0.0, false)          # mirror frame
	_p(a, c, Vector3(-3.285, 1.5, -1.2), Vector3(0.03, 0.67, 0.44), "glass", 0.0, false)
	_p(a, c, Vector3(-1.9, 0.012, -1.25), Vector3(0.5, 0.02, 0.8), "cloth_blue", 0.0, false)        # bath mat
	_p(a, c, Vector3(-3.3, 1.2, -0.5), Vector3(0.04, 0.5, 0.3), "cloth_grey", 0.0, false)           # towel
	a.stain(c, Vector3(-2.4, 2.49, -2.0), Vector3(0, -1, 0), 1.5)
	a.stain(c, Vector3(-2.8, 1.8, -2.53), Vector3(0, 0, 1), 1.0, 1.4)
	a.stain(c, Vector3(-1.4, 0.8, -2.53), Vector3(0, 0, 1), 0.8, 1.6)
	a.blob_shadow(c, Vector3(-2.49, 0, -2.165), 2.0, 1.1)


static func _dads(a: Apartment) -> void:
	var c := "dads"                                       # x[-3.34,-1.06] z[-5.94,-2.66]
	_boxes(a, c, Vector3(-3.0, 0, -5.55), 3, 2, Vector3(0.42, 0.32, 0.36))
	_boxes(a, c, Vector3(-3.05, 0, -4.7), 2, 1, Vector3(0.5, 0.36, 0.4))
	_boxes(a, c, Vector3(-3.0, 0, -3.1), 2, 2, Vector3(0.4, 0.3, 0.34))
	_p(a, c, Vector3(-1.5, 0.4, -3.55), Vector3(0.9, 0.8, 0.85), "leather", PI / 2.0 + 0.2)            # his armchair
	_p(a, c, Vector3(-1.38, 0.78, -3.58), Vector3(0.25, 0.5, 0.85), "leather", PI / 2.0 + 0.2, false)
	a.blob_shadow(c, Vector3(-1.5, 0, -3.55), 1.3, 1.3)
	_table(a, c, Vector3(-1.42, 0, -4.95), 0.5, 0.5, 0.6, "dark_wood")
	_p(a, c, Vector3(-1.42, 0.7, -4.95), Vector3(0.3, 0.18, 0.12), "black", 0.3, false)              # his radio
	_floor_lamp(a, c, Vector3(-1.3, 0, -2.9), Color(1.0, 0.7, 0.45), 0.3)
	_picture(a, c, Vector3(-1.06, 1.55, -4.2), Vector3(-1, 0, 0), 0.5, 0.4, "paper")                 # family photo
	_picture(a, c, Vector3(-3.34, 1.5, -4.2), Vector3(1, 0, 0), 0.4, 0.5, "cloth_blue")
	_litter(a, c, Vector3(-2.2, 0, -4.3), 4, 0.5, 1)
	a.stain(c, Vector3(-3.0, 2.49, -5.4), Vector3(0, -1, 0), 1.2)


static func _bedroom(a: Apartment) -> void:
	var c := "bedroom"                                    # x[-6.49,-3.46] z[-5.94,-2.66]
	_bed(a, c, Vector3(-5.44, 0, -3.9), -PI / 2.0, 1.6, 2.1)                                           # head to the west wall
	_p(a, c, Vector3(-6.22, 0.25, -5.0), Vector3(0.42, 0.5, 0.42), "dark_wood")
	_p(a, c, Vector3(-6.22, 0.25, -2.88), Vector3(0.4, 0.5, 0.4), "dark_wood")
	a.cyl(Vector3(-6.22, 0.62, -2.88), 0.05, 0.2, "brass", a.layer_of(c), 0.03, 8)                      # bedside lamp
	a.cyl(Vector3(-6.22, 0.82, -2.88), 0.1, 0.16, "lampshade", a.layer_of(c), 0.07, 10)
	_p(a, c, Vector3(-6.22, 0.55, -5.0), Vector3(0.14, 0.1, 0.1), "black", 0.4, false)                  # alarm clock
	_p(a, c, Vector3(-6.2, 0.53, -4.82), Vector3(0.1, 0.1, 0.1), "paper", 0.0, false)
	_p(a, c, Vector3(-3.76, 1.0, -5.3), Vector3(0.6, 2.0, 1.2), "dark_wood")                            # wardrobe
	_p(a, c, Vector3(-4.07, 1.0, -5.0), Vector3(0.02, 0.5, 0.02), "brass", 0.0, false)
	_p(a, c, Vector3(-4.07, 1.0, -5.6), Vector3(0.02, 0.5, 0.02), "brass", 0.0, false)
	_rug(a, c, Vector3(-5.0, 0, -3.9), 2.2, 1.6, "cloth_blue")
	_litter(a, c, Vector3(-4.1, 0, -3.9), 7, 0.5, 2)
	_picture(a, c, Vector3(-6.49, 1.65, -3.9), Vector3(1, 0, 0), 0.7, 0.5, "cloth_grey")             # picture above the bed
	a.stain(c, Vector3(-4.7, 2.49, -3.5), Vector3(0, -1, 0), 1.3)
	a.stain(c, Vector3(-3.46, 2.0, -3.2), Vector3(-1, 0, 0), 0.9, 1.0)


static func _dressing(a: Apartment) -> void:
	var c := "dressing"                                   # x[-6.49,-3.46] z[-2.54,-0.11]
	_p(a, c, Vector3(-6.25, 1.05, -1.5), Vector3(0.45, 2.1, 1.7), "dark_wood")                       # shelves
	for i in 5:
		_p(a, c, Vector3(-6.0, 0.35 + float(i) * 0.4, -1.5), Vector3(0.02, 0.02, 1.6), "paper", 0.0, false)
	_p(a, c, Vector3(-3.55, 1.72, -1.2), Vector3(0.03, 0.03, 1.8), "metal", 0.0, false)               # clothes rail
	for i in 7:
		var mat: String = ["cloth_grey", "cloth_blue", "cloth_red", "cloth_grey"][i % 4]
		_p(a, c, Vector3(-3.55, 1.2, -0.45 - float(i) * 0.22), Vector3(0.05, 1.0, 0.22), mat, 0.0, false)
	_p(a, c, Vector3(-4.8, 0.25, -0.45), Vector3(0.7, 0.5, 0.4), "leather", 0.1)                      # suitcase
	_picture(a, c, Vector3(-4.0, 1.55, -0.11), Vector3(0, 0, -1), 0.5, 1.0, "glass")                # full-length mirror
	_litter(a, c, Vector3(-5.0, 0, -1.6), 5, 0.6, 3)
	a.stain(c, Vector3(-5.0, 2.49, -1.4), Vector3(0, -1, 0), 1.0)


static func _spare(a: Apartment) -> void:
	var c := "spare"                                      # x[-6.49,-3.46] z[-9.89,-7.46]
	_bed(a, c, Vector3(-6.0, 0, -8.9), 0.0, 0.95, 2.0, "sheet", "cloth_blue")                         # Jack's old bed, head to the north
	_table(a, c, Vector3(-3.78, 0, -8.8), 0.6, 1.4, 0.74, "dark_wood", 0.0)                           # desk
	_chair(a, c, Vector3(-4.5, 0, -8.8), PI / 2.0)
	_p(a, c, Vector3(-3.8, 0.9, -9.05), Vector3(0.35, 0.3, 0.3), "black", 0.0, false)               # old monitor
	_p(a, c, Vector3(-3.8, 0.78, -8.5), Vector3(0.3, 0.02, 0.2), "paper", 0.0, false)
	_p(a, c, Vector3(-5.0, 1.0, -9.89), Vector3(0.9, 0.02, 0.28), "dark_wood", 0.0, false)            # shelf with trophies
	for i in 4:
		a.cyl(Vector3(-5.3 + float(i) * 0.22, 1.1, -9.8), 0.045, 0.15, "brass", a.layer_of(c), 0.03, 8)
	_picture(a, c, Vector3(-3.46, 1.6, -9.2), Vector3(-1, 0, 0), 0.5, 0.7, "cloth_red")              # poster
	_boxes(a, c, Vector3(-6.3, 0, -7.7), 2, 1, Vector3(0.45, 0.3, 0.4))
	_litter(a, c, Vector3(-4.3, 0, -8.1), 5, 0.6, 4)
	a.stain(c, Vector3(-4.8, 2.49, -8.8), Vector3(0, -1, 0), 1.4)


static func _utility(a: Apartment) -> void:
	var c := "utility"                                    # x[-3.34,-1.06] z[-9.89,-7.46]
	_p(a, c, Vector3(-3.0, 0.43, -9.55), Vector3(0.6, 0.86, 0.6), "white")                           # washing machine
	a.cyl(Vector3(-3.0, 0.5, -9.24), 0.17, 0.04, "black", a.layer_of(c), -1.0, 16)
	_p(a, c, Vector3(-1.5, 0.75, -9.6), Vector3(0.45, 1.5, 0.4), "white")                            # boiler
	a.cyl(Vector3(-1.5, 1.7, -9.6), 0.06, 0.4, "chrome", a.layer_of(c), -1.0, 8)
	a.cyl(Vector3(-1.5, 1.2, -9.35), 0.025, 2.4, "chrome", a.layer_of(c), -1.0, 6)
	_p(a, c, Vector3(-3.3, 1.2, -8.3), Vector3(0.03, 0.04, 1.0), "dark_wood", 0.0, false)             # shelf
	_p(a, c, Vector3(-3.25, 1.2, -8.3), Vector3(0.16, 0.04, 1.0), "dark_wood", 0.0, false)
	for i in 4:
		_p(a, c, Vector3(-3.25, 1.3, -8.0 - float(i) * 0.2), Vector3(0.1, 0.2, 0.1), ["white", "green_glass", "cloth_blue", "cloth_red"][i], 0.0, false)
	a.cyl(Vector3(-1.4, 0.18, -7.9), 0.17, 0.36, "cloth_blue", a.layer_of(c), 0.2)                    # mop bucket
	_p(a, c, Vector3(-1.2, 0.8, -8.4), Vector3(0.03, 1.6, 0.03), "dark_wood", 0.0, false)             # mop
	a.stain(c, Vector3(-2.2, 2.49, -8.7), Vector3(0, -1, 0), 1.5)
	a.stain(c, Vector3(-2.0, 0.6, -9.88), Vector3(0, 0, 1), 1.0, 1.6)
	_litter(a, c, Vector3(-2.3, 0, -8.5), 3, 0.5, 5)


static func _kitchen(a: Apartment) -> void:
	var c := "kitchen"                                    # x[0.46,4.89] z[-2.89,-0.11]
	var layer := a.layer_of(c)
	_p(a, c, Vector3(4.55, 0.9, -0.45), Vector3(0.65, 1.8, 0.65), "white")                           # fridge
	_p(a, c, Vector3(4.2, 1.1, -0.78), Vector3(0.02, 0.5, 0.03), "chrome", 0.0, false)
	_p(a, c, Vector3(1.55, 0.44, -0.41), Vector3(1.3, 0.88, 0.6), "dark_wood")                       # base unit
	_p(a, c, Vector3(2.7, 0.44, -0.41), Vector3(1.0, 0.88, 0.6), "dark_wood")                        # sink unit
	_p(a, c, Vector3(3.7, 0.44, -0.41), Vector3(0.9, 0.88, 0.6), "dark_wood")
	for x in [0.94, 1.55, 2.7, 3.7]:
		_p(a, c, Vector3(x, 0.9, -0.1 - 0.62), Vector3(0.62 if x != 0.94 else 0.02, 0.02, 0.02), "chrome", 0.0, false)
	_p(a, c, Vector3(1.55, 0.9, -0.41), Vector3(1.3, 0.04, 0.62), "metal", 0.0, false)               # worktops
	_p(a, c, Vector3(2.7, 0.9, -0.41), Vector3(1.0, 0.04, 0.62), "metal", 0.0, false)
	_p(a, c, Vector3(3.7, 0.9, -0.41), Vector3(0.9, 0.04, 0.62), "metal", 0.0, false)
	_p(a, c, Vector3(2.7, 0.91, -0.41), Vector3(0.6, 0.02, 0.4), "chrome", 0.0, false)               # sink basin
	for i in 4:                                                                                      # hob rings
		var o := Vector3(1.35 + float(i % 2) * 0.35, 0.925, -0.28 - float(i / 2) * 0.3)
		a.cyl(o, 0.1, 0.012, "black", layer, -1.0, 12)
	a.cyl(Vector3(2.7, 1.1, -0.2), 0.015, 0.4, "chrome", layer, -1.0, 6)                              # tap
	_p(a, c, Vector3(1.55, 1.65, -0.27), Vector3(1.3, 0.7, 0.32), "dark_wood", 0.0, false)           # wall cupboards
	_p(a, c, Vector3(3.9, 1.65, -0.27), Vector3(1.0, 0.7, 0.32), "dark_wood", 0.0, false)
	_table(a, c, Vector3(2.4, 0, -1.95), 0.9, 0.8, 0.75, "dark_wood")
	_chair(a, c, Vector3(2.4, 0, -1.3), 0.0)
	_chair(a, c, Vector3(2.4, 0, -2.6), PI)
	for dx in [-0.22, 0.22]:                                                                         # two plates, two cups
		a.cyl(Vector3(2.4 + dx, 0.765, -1.95), 0.11, 0.02, "white", layer, -1.0, 12)
		a.cyl(Vector3(2.4 + dx, 0.8, -2.1), 0.04, 0.07, "paper", layer, -1.0, 8)
	_p(a, c, Vector3(2.4, 0.77, -1.7), Vector3(0.12, 0.04, 0.09), "cloth_red", 0.3, false)           # pizza box corner
	for i in 5:                                                                                      # dirty dishes by the sink
		a.cyl(Vector3(3.0 + float(i % 2) * 0.12, 0.95 + float(i) * 0.04, -0.5), 0.1, 0.03, "white", layer, -1.0, 10)
	for i in 4:
		a.cyl(Vector3(4.2 - float(i) * 0.1, 0.99, -0.4 - float(i % 2) * 0.08), 0.032, 0.12, "chrome" if i % 2 == 0 else "green_glass", layer, -1.0, 8)   # cans, bottles
	a.cyl(Vector3(0.75, 0.25, -2.5), 0.2, 0.5, "black", layer, 0.17, 12)                              # bin
	_p(a, c, Vector3(0.8, 0.06, -2.2), Vector3(0.4, 0.1, 0.35), "sheet", 0.4, false)                  # bin bag overflowing
	_litter(a, c, Vector3(3.6, 0, -1.8), 4, 0.6, 6)
	a.stain(c, Vector3(2.7, 2.49, -1.5), Vector3(0, -1, 0), 1.6)
	a.stain(c, Vector3(2.7, 1.5, -0.11), Vector3(0, 0, -1), 1.0, 1.4)


static func _living(a: Apartment) -> void:
	var c := "living"                                     # x[0.46,4.89] z[-7.94,-3.06]
	var layer := a.layer_of(c)
	_p(a, c, Vector3(2.9, 0.225, -7.68), Vector3(1.5, 0.45, 0.42), "dark_wood")                      # TV stand
	_p(a, c, Vector3(2.9, 0.98, -7.72), Vector3(1.15, 0.68, 0.06), "black", 0.0, false)              # TV
	_p(a, c, Vector3(2.9, 0.98, -7.685), Vector3(1.07, 0.6, 0.01), "glass", 0.0, false)
	_p(a, c, Vector3(2.9, 0.6, -7.7), Vector3(0.1, 0.3, 0.1), "black", 0.0, false)
	_sofa(a, c, Vector3(2.9, 0, -5.1), 0.0, 2.1)
	_p(a, c, Vector3(2.4, 0.58, -5.2), Vector3(0.9, 0.1, 0.6), "cloth_grey", 0.3, false)             # blanket thrown on the sofa
	_table(a, c, Vector3(2.9, 0, -6.4), 1.0, 0.55, 0.42, "dark_wood")
	_p(a, c, Vector3(2.7, 0.45, -6.4), Vector3(0.34, 0.05, 0.3), "cloth_red", 0.2, false)            # pizza box
	for i in 4:
		a.cyl(Vector3(3.1 + float(i) * 0.08, 0.5, -6.35 + float(i % 2) * 0.1), 0.032, 0.12, "chrome", layer, -1.0, 8)
	_rug(a, c, Vector3(2.9, 0, -6.2), 2.2, 1.6, "cloth_blue")
	_table(a, c, Vector3(0.82, 0, -3.95), 0.6, 1.3, 0.75, "dark_wood")                               # desk
	_chair(a, c, Vector3(1.5, 0, -3.95), PI / 2.0)
	_p(a, c, Vector3(0.82, 0.78, -3.8), Vector3(0.3, 0.02, 0.22), "metal", 0.0, false)               # laptop
	_p(a, c, Vector3(0.78, 0.9, -3.93), Vector3(0.02, 0.2, 0.28), "black", 0.1, false)
	for i in 6:
		_p(a, c, Vector3(0.85, 0.78 + float(i) * 0.008, -4.3 + float(i % 3) * 0.05), Vector3(0.22, 0.008, 0.3), "paper", float(i) * 0.5, false)   # job applications
	_p(a, c, Vector3(0.65, 0.95, -7.3), Vector3(0.32, 1.9, 1.1), "dark_wood")                         # bookshelf
	for i in 4:
		_books(a, c, Vector3(0.65, 0.2 + float(i) * 0.42, -7.8), Vector3(0, 0, 1), 12, 0.3, 0.22, i)
	_floor_lamp(a, c, Vector3(4.6, 0, -3.5))
	_picture(a, c, Vector3(4.89, 1.7, -3.6), Vector3(-1, 0, 0), 0.5, 0.4, "paper")
	_picture(a, c, Vector3(1.2, 1.7, -7.94), Vector3(0, 0, 1), 0.7, 0.5, "cloth_grey")
	_litter(a, c, Vector3(1.6, 0, -5.4), 8, 0.9, 7)
	a.stain(c, Vector3(4.0, 2.49, -5.5), Vector3(0, -1, 0), 1.8)
	a.stain(c, Vector3(1.0, 2.49, -4.0), Vector3(0, -1, 0), 1.2)
	a.stain(c, Vector3(4.89, 0.7, -7.0), Vector3(-1, 0, 0), 1.0, 1.5)


static func _box_room(a: Apartment) -> void:
	var c := "box"                                        # x[0.46,2.54] z[-9.89,-8.06]
	_p(a, c, Vector3(2.25, 0.85, -9.6), Vector3(0.5, 1.7, 0.5), "sheet", 0.4)                        # something under a sheet
	_p(a, c, Vector3(2.25, 1.72, -9.6), Vector3(0.28, 0.3, 0.28), "sheet", 0.4, false)
	_p(a, c, Vector3(1.95, 0.4, -8.45), Vector3(0.8, 0.8, 0.7), "sheet", 0.1)                        # covered armchair
	_boxes(a, c, Vector3(0.62, 0, -9.72), 3, 2, Vector3(0.4, 0.3, 0.34))
	_boxes(a, c, Vector3(0.62, 0, -8.3), 2, 1, Vector3(0.4, 0.3, 0.3))
	_p(a, c, Vector3(1.5, 1.4, -9.88), Vector3(1.6, 0.03, 0.3), "dark_wood", 0.0, false)              # shelf with paint tins
	for i in 5:
		a.cyl(Vector3(0.9 + float(i) * 0.3, 1.5, -9.8), 0.07, 0.15, "metal", a.layer_of(c), -1.0, 10)
	_litter(a, c, Vector3(1.5, 0, -9.0), 3, 0.4, 8)
	a.stain(c, Vector3(1.5, 2.49, -9.0), Vector3(0, -1, 0), 1.3)


static func _study(a: Apartment) -> void:
	var c := "study"                                      # x[2.66,4.89] z[-9.89,-8.06]
	_table(a, c, Vector3(3.2, 0, -9.58), 1.4, 0.6, 0.74, "dark_wood")
	_chair(a, c, Vector3(3.0, 0, -8.95), 0.0)
	_p(a, c, Vector3(2.9, 0.92, -9.6), Vector3(0.36, 0.34, 0.36), "paper", 0.0, false)               # old computer
	_p(a, c, Vector3(2.9, 0.95, -9.43), Vector3(0.3, 0.26, 0.02), "black", 0.0, false)
	_p(a, c, Vector3(3.6, 0.77, -9.55), Vector3(0.25, 0.02, 0.18), "paper", 0.2, false)
	_p(a, c, Vector3(4.75, 0.9, -8.5), Vector3(0.28, 1.8, 0.8), "dark_wood")                          # filing shelves
	_books(a, c, Vector3(4.75, 0.2, -8.1), Vector3(0, 0, -1), 9, 0.3, 0.22, 9)
	_plant(a, c, Vector3(4.55, 0.0, -9.6))
	_litter(a, c, Vector3(3.6, 0, -8.6), 4, 0.5, 10)
	a.stain(c, Vector3(3.8, 2.49, -9.0), Vector3(0, -1, 0), 1.2)
