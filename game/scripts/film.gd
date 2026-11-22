class_name Film
## Colour grades for the full-screen film shader, plus the pixel/dither filter ("FX") that
## stacks on top of any grade. One number, `fx amount` (0..1), drives the filter: the image
## gets chunkier, loses colour levels and shows an ordered-dither pattern as it rises. In AUTO
## the amount follows the world's fear value, so the picture degrades as the story does.

const GRADES := [
	{"name": "DAMP", "sat": 0.78, "shadow": Vector3(0.90, 1.00, 1.04), "high": Vector3(1.04, 1.00, 0.90), "contrast": 1.08, "grain": 0.040, "vignette": 0.38},
	{"name": "COLD", "sat": 0.62, "shadow": Vector3(0.84, 0.98, 1.10), "high": Vector3(0.96, 1.02, 1.06), "contrast": 1.12, "grain": 0.045, "vignette": 0.42},
	{"name": "SICKLY", "sat": 0.70, "shadow": Vector3(0.92, 1.06, 0.94), "high": Vector3(1.06, 1.04, 0.86), "contrast": 1.10, "grain": 0.050, "vignette": 0.44},
	{"name": "RAW", "sat": 1.0, "shadow": Vector3.ONE, "high": Vector3.ONE, "contrast": 1.0, "grain": 0.0, "vignette": 0.0},
]

const FX_NAMES := ["OFF", "LOW", "MID", "HIGH", "AUTO"]
const FX_FIXED := [0.0, 0.3, 0.6, 0.95]          ## amounts for the fixed levels; AUTO uses the fear value
const FX_AUTO := 4


static func grade_name(i: int) -> String:
	return GRADES[i % GRADES.size()]["name"]


static func fx_name(i: int) -> String:
	return FX_NAMES[i % FX_NAMES.size()]


## The filter amount for a setting: fixed levels, or the live fear value in AUTO.
static func fx_amount(fx_index: int, fear: float) -> float:
	return fear if fx_index == FX_AUTO else FX_FIXED[clampi(fx_index, 0, FX_FIXED.size() - 1)]


static func apply(mat: ShaderMaterial, grade_index: int, brightness: float, amount: float) -> void:
	var g: Dictionary = GRADES[grade_index % GRADES.size()]
	var f := clampf(amount, 0.0, 1.0)
	mat.set_shader_parameter("saturation", g["sat"])
	mat.set_shader_parameter("shadow_tint", g["shadow"])
	mat.set_shader_parameter("highlight_tint", g["high"])
	mat.set_shader_parameter("contrast", g["contrast"])
	mat.set_shader_parameter("grain", g["grain"])
	mat.set_shader_parameter("vignette", g["vignette"])
	mat.set_shader_parameter("exposure", brightness * (1.0 + 0.3 * f))   # the filter eats light, give some back
	mat.set_shader_parameter("fear", f * 0.8)
	if f < 0.02:
		mat.set_shader_parameter("pixel_size", 1.0)
		mat.set_shader_parameter("levels", 256.0)
		mat.set_shader_parameter("dither_amount", 0.0)
		mat.set_shader_parameter("glitch", 0.0)
	else:
		mat.set_shader_parameter("pixel_size", lerpf(1.0, 4.0, smoothstep(0.05, 1.0, f)))
		mat.set_shader_parameter("levels", lerpf(48.0, 6.0, pow(f, 0.8)))
		mat.set_shader_parameter("dither_amount", clampf(f * 1.6, 0.0, 1.0))
		mat.set_shader_parameter("glitch", smoothstep(0.65, 1.0, f))
