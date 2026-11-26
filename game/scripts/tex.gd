class_name Tex
## Small procedural greyscale textures (nearest-filtered, tiled in world space).
## Generated at startup in a few ms, so there are no image assets to ship yet.

static var _cache := {}


static func _make(size: int, key: String, fn: Callable) -> ImageTexture:
	if key != "" and _cache.has(key):
		return _cache[key]
	var img := Image.create(size, size, true, Image.FORMAT_RGB8)
	for y in size:
		for x in size:
			var v: float = clampf(fn.call(x, y), 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v, v))
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	if key != "":
		_cache[key] = tex
	return tex


## Tileable value noise in [0, 1]: `cell` pixels per lattice step on a `size` pixel tile.
static func _vnoise(x: int, y: int, cell: int, size: int, seed: int) -> float:
	var n := size / cell
	var gx := x / cell
	var gy := y / cell
	var fx := float(x % cell) / cell
	var fy := float(y % cell) / cell
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var a := _hash((gx % n) + seed * 131, (gy % n) + seed * 71)
	var b := _hash(((gx + 1) % n) + seed * 131, (gy % n) + seed * 71)
	var c := _hash((gx % n) + seed * 131, ((gy + 1) % n) + seed * 71)
	var d := _hash(((gx + 1) % n) + seed * 131, ((gy + 1) % n) + seed * 71)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)


## 128 px = 2 m. Whitewashed coursed masonry: pale blocks in 0.25 m courses, dark joints, rain streaks running down.
static func masonry() -> ImageTexture:
	return _make(128, "masonry", func(x: int, y: int) -> float:
		var row := y / 16
		var off := (row % 2) * 16
		var bx := (x + off) % 32
		var streak := (_vnoise(x, 0, 8, 128, 5) - 0.5) * 0.16 + (_vnoise(x, y, 32, 128, 9) - 0.5) * 0.10
		if y % 16 == 0 or bx == 0:
			return 0.42 + streak * 0.5
		var block := 0.80 + (_hash(row, (x + off) / 32) - 0.5) * 0.12
		var edge := 0.0
		if y % 16 == 1 or bx == 1:
			edge = -0.07                         # the block edges catch shadow
		return block + edge + streak + (_vnoise(x, y, 4, 128, 3) - 0.5) * 0.08 + (_hash(x, y) - 0.5) * 0.04)


## 128 px = 2 m. Rough island rock: blotches, grain, and dark cracks.
static func rock() -> ImageTexture:
	return _make(128, "rock", func(x: int, y: int) -> float:
		var v := 0.48 + (_vnoise(x, y, 32, 128, 1) - 0.5) * 0.40 + (_vnoise(x, y, 16, 128, 2) - 0.5) * 0.22
		v += (_vnoise(x, y, 4, 128, 4) - 0.5) * 0.14 + (_hash(x, y) - 0.5) * 0.06
		var crack := absf(_vnoise(x, y, 16, 128, 7) - 0.5) + (_hash(x, y) - 0.5) * 0.02
		if crack < 0.012:
			v -= 0.22
		return v)


## 128 px = 2 m. Worn stone slabs (floors, steps).
static func flagstone() -> ImageTexture:
	return _make(128, "flagstone", func(x: int, y: int) -> float:
		var row := y / 32
		var off := (row % 2) * 21
		var bx := (x + off) % 64
		if y % 32 == 0 or bx == 0:
			return 0.16
		var slab := 0.50 + (_hash(row, ((x + off) % 128) / 64) - 0.5) * 0.18
		return slab + (_vnoise(x, y, 8, 128, 6) - 0.5) * 0.14 + (_hash(x, y) - 0.5) * 0.05)


static func _hash(a: int, b: int) -> float:
	var h := (a * 374761393 + b * 668265263) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h & 0xffff) / 65535.0


## 64 px = 1 m. Stone blocks with dark mortar.
static func bricks() -> ImageTexture:
	return _make(64, "bricks", func(x: int, y: int) -> float:
		var row := y / 8
		var off := (row % 2) * 8
		var bx := (x + off) % 16
		if y % 8 == 0 or bx == 0:
			return 0.20
		var base := 0.38 + _hash(row, (x + off) / 16) * 0.16
		return base + (_hash(x, y) - 0.5) * 0.02)


## 64 px = 1 m. Vertical planks with grain.
static func planks() -> ImageTexture:
	return _make(64, "planks", func(x: int, y: int) -> float:
		var plank := x / 16
		if x % 16 == 0:
			return 0.08
		var base := 0.42 + _hash(plank, 7) * 0.16
		var grain := sin(float(y) * 0.55 + float(plank) * 2.3 + _hash(x, y / 8) * 3.0) * 0.05
		return base + grain * 0.7 + (_hash(x, y) - 0.5) * 0.02)


## 32 px = 0.5 m. Woven sacking.
static func burlap() -> ImageTexture:
	return _make(32, "burlap", func(x: int, y: int) -> float:
		var weave := 0.07 if (x + y) % 2 == 0 else -0.04
		if x % 8 == 0 or y % 8 == 0:
			weave -= 0.10
		return 0.55 + weave * 0.8 + (_hash(x, y) - 0.5) * 0.05)


## 32 px = 1 m. Rough dark plaster / metal.
static func rough() -> ImageTexture:
	return _make(32, "rough", func(x: int, y: int) -> float:
		return 0.34 + (_hash(x, y) - 0.5) * 0.03 + (_hash(x / 4, y / 4) - 0.5) * 0.07)


## 32 px = 2 m. Whitewashed plaster: almost flat, with big soft patches.
static func plaster() -> ImageTexture:
	return _make(32, "plaster", func(x: int, y: int) -> float:
		return 0.80 + (_hash(x / 8, y / 8) - 0.5) * 0.10 + (_hash(x, y) - 0.5) * 0.02)


## World-space triplanar material so boxes of any size share one texel density.
static func material(tex: Texture2D, tile_m: float, tint := 1.0, normal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	if normal > 0.0:
		m.normal_enabled = true
		m.normal_texture = normal_map(tex as ImageTexture, normal)
		m.normal_scale = 1.0
	m.albedo_texture = tex
	m.albedo_color = Color(tint, tint, tint)
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / tile_m
	# Nearest keeps texels crisp up close; mipmaps stop the moire shimmer far away.
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.roughness = 1.0
	return m


static var _normals := {}


## A normal map made from a texture's brightness (dark joints and cracks read as grooves).
static func normal_map(tex: ImageTexture, strength: float) -> ImageTexture:
	var key := [tex, strength]
	if _normals.has(key):
		return _normals[key]
	var img := tex.get_image().duplicate() as Image
	img.clear_mipmaps()
	img.convert(Image.FORMAT_RGBA8)
	img.bump_map_to_normal_map(strength)
	img.generate_mipmaps()
	var out := ImageTexture.create_from_image(img)
	_normals[key] = out
	return out
