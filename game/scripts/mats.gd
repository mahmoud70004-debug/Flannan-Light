class_name Mats
## Material library. Photo-scanned PBR sets (ambientCG, CC0) from res://assets/textures/pbr,
## plus a few plain colours. Textured materials expect UVs in tiles (metres / tile_m),
## which RoomKit writes itself, so there is no triplanar cost at runtime.

const DIR := "res://assets/textures/pbr/"

## key -> {tex: file stem or "", tile: metres per texture repeat, tint, rough, metal, normal: strength}
const TABLE := {
	"wall": {"tex": "wall", "tile": 2.0, "tint": Color(0.80, 0.78, 0.70), "rough": 0.95},
	"wall_damp": {"tex": "wall_damp", "tile": 1.6, "tint": Color(0.72, 0.74, 0.70), "rough": 0.95},
	"floor_hall": {"tex": "floor_hall", "tile": 1.6, "tint": Color(0.85, 0.82, 0.80), "rough": 0.55},
	"floor_wood": {"tex": "floor_wood", "tile": 1.6, "tint": Color(0.82, 0.78, 0.74), "rough": 0.6},
	"tile": {"tex": "tile", "tile": 1.2, "tint": Color(0.82, 0.84, 0.84), "rough": 0.35},
	"ceiling": {"tex": "ceiling", "tile": 2.0, "tint": Color(0.78, 0.77, 0.72), "rough": 1.0},
	"fabric": {"tex": "fabric", "tile": 0.9, "tint": Color(0.62, 0.58, 0.52), "rough": 1.0},
	"dark_wood": {"tex": "dark_wood", "tile": 1.0, "tint": Color(0.80, 0.74, 0.70), "rough": 0.6},
	"white": {"tex": "", "tint": Color(0.74, 0.74, 0.72), "rough": 0.35},
	"paint": {"tex": "", "tint": Color(0.60, 0.58, 0.53), "rough": 0.7},
	"black": {"tex": "", "tint": Color(0.03, 0.03, 0.035), "rough": 0.3},
	"metal": {"tex": "", "tint": Color(0.55, 0.56, 0.58), "rough": 0.35, "metal": 0.7},
	"cardboard": {"tex": "", "tint": Color(0.36, 0.27, 0.17), "rough": 0.95},
	"glass": {"tex": "", "tint": Color(0.05, 0.06, 0.07), "rough": 0.05, "metal": 0.4},
	"door": {"tex": "", "tint": Color(0.62, 0.58, 0.50), "rough": 0.55},
	"trim": {"tex": "", "tint": Color(0.70, 0.68, 0.62), "rough": 0.5},
	"brass": {"tex": "", "tint": Color(0.55, 0.42, 0.22), "rough": 0.35, "metal": 0.8},
	"leather": {"tex": "", "tint": Color(0.16, 0.10, 0.07), "rough": 0.5},
	"cloth_grey": {"tex": "", "tint": Color(0.30, 0.30, 0.32), "rough": 1.0},
	"cloth_blue": {"tex": "", "tint": Color(0.12, 0.16, 0.24), "rough": 1.0},
	"cloth_red": {"tex": "", "tint": Color(0.30, 0.10, 0.09), "rough": 1.0},
	"paper": {"tex": "", "tint": Color(0.72, 0.70, 0.64), "rough": 0.9},
	"sheet": {"tex": "", "tint": Color(0.62, 0.62, 0.60), "rough": 1.0},
	"curtain": {"tex": "fabric", "tile": 0.7, "tint": Color(0.42, 0.34, 0.28), "rough": 1.0},
	"lampshade": {"tex": "", "tint": Color(0.78, 0.70, 0.52), "rough": 0.9},
	"green_glass": {"tex": "", "tint": Color(0.06, 0.16, 0.08), "rough": 0.1, "metal": 0.2},
	"chrome": {"tex": "", "tint": Color(0.7, 0.7, 0.72), "rough": 0.15, "metal": 0.9},
}

static var _cache := {}


static func tile_of(key: String) -> float:
	return float((TABLE[key] as Dictionary).get("tile", 1.0))


## Metres per texture repeat for UV generation: textured materials only, else 1.
static func uv_tile(key: String) -> float:
	if not TABLE.has(key):
		return 1.0
	var d: Dictionary = TABLE[key]
	return float(d.get("tile", 1.0)) if d.get("tex", "") != "" else 1.0


## Plain-colour materials are merged per surface type and coloured per vertex, so a room's
## props cost one draw call per type instead of one per colour.
static func is_plain(key: String) -> bool:
	return TABLE.has(key) and (TABLE[key] as Dictionary).get("tex", "") == ""


static func color_of(key: String) -> Color:
	return (TABLE[key] as Dictionary)["tint"]


## The batch a material's faces are merged into: itself if textured, else its surface group.
static func batch_key(key: String) -> String:
	if not is_plain(key):
		return key
	var d: Dictionary = TABLE[key]
	if d.get("metal", 0.0) >= 0.5:
		return "g_metal"
	if d["rough"] < 0.45:
		return "g_gloss"
	return "g_matte"


static func get_mat(key: String) -> StandardMaterial3D:
	if key.begins_with("g_"):
		if _cache.has(key):
			return _cache[key]
		var g := StandardMaterial3D.new()
		g.vertex_color_use_as_albedo = true
		g.vertex_color_is_srgb = true
		g.roughness = {"g_matte": 0.85, "g_gloss": 0.28, "g_metal": 0.3}[key]
		g.metallic = 0.75 if key == "g_metal" else 0.0
		g.metallic_specular = 0.35
		_cache[key] = g
		return g
	if key == "_stain":
		return stain_mat()
	if key == "_ao":
		return ao_mat()
	if _cache.has(key):
		return _cache[key]
	var d: Dictionary = TABLE[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = d["tint"]
	m.roughness = d["rough"]
	m.metallic = d.get("metal", 0.0)
	m.metallic_specular = 0.35
	var stem: String = d["tex"]
	if stem != "":
		m.albedo_texture = load(DIR + stem + "_c.jpg")
		m.normal_enabled = true
		m.normal_texture = load(DIR + stem + "_n.jpg")
		m.normal_scale = 0.8
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_cache[key] = m
	return m


## A soft dark blotch (water stain, grime): alpha fades out radially. UVs 0..1 across the quad.
static func stain_mat() -> StandardMaterial3D:
	if _cache.has("_stain"):
		return _cache["_stain"]
	var grad := Gradient.new()
	grad.set_color(0, Color(0.10, 0.07, 0.04, 0.62))
	grad.set_color(1, Color(0.10, 0.07, 0.04, 0.0))
	grad.add_point(0.55, Color(0.09, 0.07, 0.05, 0.30))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 1.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cache["_stain"] = m
	return m


## A dark vertical gradient strip (fake ambient occlusion in corners and under furniture).
static func ao_mat() -> StandardMaterial3D:
	if _cache.has("_ao"):
		return _cache["_ao"]
	var grad := Gradient.new()
	grad.set_color(0, Color(0.0, 0.0, 0.0, 0.0))
	grad.set_color(1, Color(0.0, 0.0, 0.0, 0.62))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.0, 0.0)
	tex.fill_to = Vector2(0.0, 1.0)
	tex.width = 8
	tex.height = 64
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cache["_ao"] = m
	return m


## An unshaded glowing surface (bulbs, windows).
static func glow(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	return m
