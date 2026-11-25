shader_type spatial;
render_mode unshaded, cull_front, fog_disabled, shadows_disabled;   // opaque, so transparent things (beam, halos) draw over it
// A dome of heavy, slowly moving storm clouds around the camera. Grey only: the post shader turns brightness
// into the film look. At night the lighthouse lantern lights the clouds around it (glow toward glow_dir).

uniform vec3 top_color = vec3(0.30);
uniform vec3 horizon_color = vec3(0.55);
uniform float cloud_cover = 0.65;
uniform float cloud_bright = 0.72;
uniform float cloud_dark = 0.32;
uniform vec3 glow_dir = vec3(0.0, 0.3, -1.0);
uniform float glow = 0.0;
uniform float speed = 0.012;

varying vec3 dir;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void vertex() {
	dir = normalize((MODEL_MATRIX * vec4(VERTEX, 0.0)).xyz);
}

void fragment() {
	vec3 d = normalize(dir);
	float h = max(d.y, 0.0);
	vec2 p = d.xz / (d.y + 0.22) * 1.3 + vec2(TIME * speed, TIME * speed * 0.35);
	float n = fbm(p);
	float cloud = smoothstep(1.0 - cloud_cover, 1.0 - cloud_cover + 0.35, n);
	float shade = fbm(p * 2.4 + vec2(3.1, 0.7));                 // lighter rims, darker bellies
	vec3 base = mix(horizon_color, top_color, smoothstep(0.0, 0.7, h));
	vec3 c = mix(base, vec3(mix(cloud_dark, cloud_bright, shade)), cloud);
	float g = max(dot(d, normalize(glow_dir)), 0.0);
	c += (pow(g, 18.0) * 0.6 + pow(g, 4.0) * 0.12) * glow * (0.4 + 0.6 * cloud);
	c = mix(horizon_color, c, smoothstep(-0.03, 0.16, d.y));     // melts into the fog at the horizon
	ALBEDO = clamp(c, 0.0, 1.0);
}
