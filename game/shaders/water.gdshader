shader_type spatial;
render_mode unshaded;
// Sea: a flat plane with blocky glints and surf. The shore mask (baked from the
// island by Blender) is 1 at the waterline and fades to 0 about 10 m out; moving
// bands of foam ride on it.

uniform float base : hint_range(0.0, 1.0) = 0.22;
uniform float glint : hint_range(0.0, 1.0) = 0.25;
uniform sampler2D shore_mask : filter_linear, repeat_disable, hint_default_black;
uniform vec4 bounds = vec4(-105.0, -80.0, 210.0, 160.0);     // min x, min z, size x, size z
uniform float foam_level : hint_range(0.0, 1.0) = 0.9;

varying vec3 wpos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float swell = (sin(wpos.x * 0.30 + TIME * 0.7) + sin(wpos.z * 0.37 - TIME * 0.5) + sin((wpos.x + wpos.z) * 0.18 + TIME * 0.4)) / 3.0;
	vec2 cell = floor(wpos.xz * 0.9);
	float h = hash(cell);
	float on = step(0.93, sin(TIME * 1.3 + h * 6.2831) * 0.5 + 0.5) * step(0.82, h);
	float v = base + swell * 0.03 + on * glint;

	vec2 uv = (wpos.xz - bounds.xy) / bounds.zw;
	float mask = 0.0;
	if (uv.x > 0.0 && uv.x < 1.0 && uv.y > 0.0 && uv.y < 1.0) {
		mask = texture(shore_mask, uv).r;
	}
	// Surf: bands travelling toward the shore, broken up by blocky noise.
	float band = sin(mask * 26.0 - TIME * 1.6 + hash(floor(wpos.xz * 0.5)) * 2.0) * 0.5 + 0.5;
	float surf = step(1.0 - foam_level * mask * 0.85, band * (0.55 + 0.45 * mask)) * step(0.06, mask);
	float shore = smoothstep(0.78, 1.0, mask);
	ALBEDO = vec3(clamp(v + surf * 0.3 + shore * 0.14, 0.0, 1.0));
}
