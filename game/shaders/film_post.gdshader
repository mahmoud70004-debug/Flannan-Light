shader_type canvas_item;
// Full-screen film look applied to the 3D image: grade, soft bloom, vignette,
// a touch of lens colour fringing and moving grain. `fear` pushes it toward
// drained colour, a tighter vignette and heavier grain.

uniform float exposure = 1.0;
uniform float contrast = 1.08;
uniform float saturation = 0.8;
uniform vec3 shadow_tint = vec3(0.9, 1.0, 1.04);
uniform vec3 highlight_tint = vec3(1.04, 1.0, 0.9);
uniform float grain = 0.04;
uniform float vignette = 0.38;
uniform float fringe = 0.0016;
uniform float bloom = 0.22;
uniform float fear = 0.0;
uniform float blackout = 0.0;            // 0 normal .. 1 fully black (blinks, lights out)

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	vec2 d = uv - 0.5;
	float r2 = dot(d, d);
	vec2 off = d * fringe * (1.0 + fear * 2.0) * (0.4 + r2 * 4.0);
	vec3 col;
	col.r = texture(TEXTURE, uv + off).r;
	col.g = texture(TEXTURE, uv).g;
	col.b = texture(TEXTURE, uv - off).b;

	// Cheap bloom: a few wide taps of the bright parts.
	vec2 px = 1.0 / vec2(textureSize(TEXTURE, 0));
	vec3 glow = vec3(0.0);
	for (int i = 0; i < 4; i++) {
		float a = 6.2831853 * (float(i) + 0.5) / 4.0;
		vec2 o = vec2(cos(a), sin(a)) * 5.0 * px;
		glow += max(texture(TEXTURE, uv + o).rgb - 0.55, 0.0);
	}
	col += glow * 0.25 * bloom;

	col *= exposure;
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = (col - 0.5) * contrast + 0.5;
	col = mix(vec3(l), col, saturation * (1.0 - fear * 0.55));
	col *= mix(shadow_tint, highlight_tint, smoothstep(0.1, 0.8, l));

	float v = vignette + fear * 0.35;
	col *= 1.0 - v * smoothstep(0.18, 0.78, sqrt(r2) * 1.55);

	float g = (hash21(uv * vec2(textureSize(TEXTURE, 0)) + floor(TIME * 24.0) * 13.7) - 0.5) * (grain + fear * 0.05);
	col += g * (1.0 - 0.6 * l);

	col *= 1.0 - blackout;
	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
