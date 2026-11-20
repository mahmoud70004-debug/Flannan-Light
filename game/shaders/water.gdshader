shader_type spatial;
render_mode unshaded;
// Night sea: a dark flat plane with blocky moon glints that come and go.

uniform float base : hint_range(0.0, 1.0) = 0.12;
uniform float glint : hint_range(0.0, 1.0) = 0.55;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float swell = (sin(wpos.x * 0.30 + TIME * 0.7) + sin(wpos.z * 0.37 - TIME * 0.5) + sin((wpos.x + wpos.z) * 0.18 + TIME * 0.4)) / 3.0;
	vec2 cell = floor(wpos.xz * 0.9);
	float h = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
	float on = step(0.93, sin(TIME * 1.3 + h * 6.2831) * 0.5 + 0.5) * step(0.82, h);
	float v = base + swell * 0.03 + on * glint;
	ALBEDO = vec3(v);
}
