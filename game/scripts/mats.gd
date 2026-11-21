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
}

static var _cache := {}


static func tile_of(key: String) -> float:
	return float((TABLE[key] as Dictionary).get("tile", 1.0))


static func get_mat(key: String) -> StandardMaterial3D:
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


## An unshaded glowing surface (bulbs, windows).
static func glow(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	return m
