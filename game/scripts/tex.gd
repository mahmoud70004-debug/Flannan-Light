class_name Tex
## Small procedural greyscale textures (nearest-filtered, tiled in world space).
## Generated at startup in a few ms, so there are no image assets to ship yet.

static func _make(size: int, fn: Callable) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y in size:
		for x in size:
			var v: float = clampf(fn.call(x, y), 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v, v))
	return ImageTexture.create_from_image(img)


static func _hash(a: int, b: int) -> float:
	var h := (a * 374761393 + b * 668265263) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h & 0xffff) / 65535.0


## 64 px = 1 m. Stone blocks with dark mortar.
static func bricks() -> ImageTexture:
	return _make(64, func(x: int, y: int) -> float:
		var row := y / 8
		var off := (row % 2) * 8
		var bx := (x + off) % 16
		if y % 8 == 0 or bx == 0:
			return 0.20
		var base := 0.38 + _hash(row, (x + off) / 16) * 0.16
		return base + (_hash(x, y) - 0.5) * 0.07)


## 64 px = 1 m. Vertical planks with grain.
static func planks() -> ImageTexture:
	return _make(64, func(x: int, y: int) -> float:
		var plank := x / 16
		if x % 16 == 0:
			return 0.08
		var base := 0.42 + _hash(plank, 7) * 0.16
		var grain := sin(float(y) * 0.55 + float(plank) * 2.3 + _hash(x, y / 8) * 3.0) * 0.05
		return base + grain + (_hash(x, y) - 0.5) * 0.06)


## 32 px = 0.5 m. Woven sacking.
static func burlap() -> ImageTexture:
	return _make(32, func(x: int, y: int) -> float:
		var weave := 0.07 if (x + y) % 2 == 0 else -0.04
		if x % 8 == 0 or y % 8 == 0:
			weave -= 0.10
		return 0.55 + weave + (_hash(x, y) - 0.5) * 0.16)


## 32 px = 1 m. Rough dark plaster / metal.
static func rough() -> ImageTexture:
	return _make(32, func(x: int, y: int) -> float:
		return 0.30 + (_hash(x, y) - 0.5) * 0.18 + (_hash(x / 4, y / 4) - 0.5) * 0.12)


## World-space triplanar material so boxes of any size share one texel density.
static func material(tex: Texture2D, tile_m: float, tint := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.albedo_color = Color(tint, tint, tint)
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / tile_m
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.roughness = 1.0
	return m
