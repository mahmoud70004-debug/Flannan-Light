shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_opaque;
// Each fly is a quad collapsed to a point (all vertices at the origin); COLOR holds its random
// seeds and UV the corner (-1..1). The vertex stage flies it around the origin and unfolds it
// into a small camera-facing square, so the swarm costs one draw call and no CPU.

uniform float radius = 0.28;
uniform float size = 0.016;
uniform float amount : hint_range(0.0, 1.0) = 1.0;
varying vec2 corner;

void vertex() {
	float t = TIME;
	vec3 s = COLOR.rgb;
	vec3 c = vec3(
		sin(t * (1.7 + s.x * 2.2) + s.y * 31.0),
		0.55 * sin(t * (2.3 + s.y * 1.7) + s.z * 21.0),
		sin(t * (1.3 + s.z * 2.6) + s.x * 27.0)) * radius;
	c += 0.035 * vec3(sin(t * 23.0 + s.x * 51.0), sin(t * 19.0 + s.y * 43.0), sin(t * 29.0 + s.z * 61.0));
	float shown = step(COLOR.a, amount);                           // fewer flies at low intensity
	vec4 view_pos = MODELVIEW_MATRIX * vec4(c, 1.0);
	view_pos.xy += UV * size * shown;
	POSITION = PROJECTION_MATRIX * view_pos;
	corner = UV;
}

void fragment() {
	if (length(corner) > 1.0) {
		discard;
	}
	ALBEDO = vec3(0.02, 0.02, 0.025);
}
