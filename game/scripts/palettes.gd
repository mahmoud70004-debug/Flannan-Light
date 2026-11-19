class_name Palettes
## Selectable looks. Each preset is the list of tones the dither shader maps
## brightness onto, darkest first. At most MAX_TONES.

const MAX_TONES := 6

const PRESETS := [
	{"name": "REFERENCE", "colors": [Color("0a0506"), Color("2b1514"), Color("6b3d37"), Color("b9806f"), Color("e8c9b0")]},
	{"name": "1-BIT", "colors": [Color("000000"), Color("f2f2f2")]},
	{"name": "ASH", "colors": [Color("050505"), Color("454545"), Color("9a9a9a"), Color("ececec")]},
	{"name": "WARM", "colors": [Color("0b0705"), Color("4a2c1f"), Color("a06a48"), Color("f0d9b5")]},
	{"name": "COLD", "colors": [Color("04070b"), Color("1d3040"), Color("5f8097"), Color("d8e6ee")]},
]


static func count() -> int:
	return PRESETS.size()


static func preset_name(index: int) -> String:
	return PRESETS[index % PRESETS.size()]["name"]


static func colors(index: int) -> Array:
	return PRESETS[index % PRESETS.size()]["colors"]


static func apply(mat: ShaderMaterial, index: int) -> void:
	var cols: Array = colors(index)
	mat.set_shader_parameter("levels", cols.size())
	for i in MAX_TONES:
		var c: Color = cols[mini(i, cols.size() - 1)]
		mat.set_shader_parameter("c%d" % i, Vector3(c.r, c.g, c.b))
