class_name Film
## Colour grades for the full-screen film shader. `fear` (0..1) is driven by the story
## later: it drains colour, tightens the vignette and thickens the grain.

const GRADES := [
	{"name": "DAMP", "sat": 0.78, "shadow": Vector3(0.90, 1.00, 1.04), "high": Vector3(1.04, 1.00, 0.90), "contrast": 1.08, "grain": 0.040, "vignette": 0.38},
	{"name": "COLD", "sat": 0.62, "shadow": Vector3(0.84, 0.98, 1.10), "high": Vector3(0.96, 1.02, 1.06), "contrast": 1.12, "grain": 0.045, "vignette": 0.42},
	{"name": "SICKLY", "sat": 0.70, "shadow": Vector3(0.92, 1.06, 0.94), "high": Vector3(1.06, 1.04, 0.86), "contrast": 1.10, "grain": 0.050, "vignette": 0.44},
	{"name": "RAW", "sat": 1.0, "shadow": Vector3.ONE, "high": Vector3.ONE, "contrast": 1.0, "grain": 0.0, "vignette": 0.0},
]


static func grade_name(i: int) -> String:
	return GRADES[i % GRADES.size()]["name"]


static func apply(mat: ShaderMaterial, grade_index: int, brightness: float, fear := 0.0) -> void:
	var g: Dictionary = GRADES[grade_index % GRADES.size()]
	mat.set_shader_parameter("saturation", g["sat"])
	mat.set_shader_parameter("shadow_tint", g["shadow"])
	mat.set_shader_parameter("highlight_tint", g["high"])
	mat.set_shader_parameter("contrast", g["contrast"])
	mat.set_shader_parameter("grain", g["grain"])
	mat.set_shader_parameter("vignette", g["vignette"])
	mat.set_shader_parameter("exposure", brightness)
	mat.set_shader_parameter("fear", fear)
