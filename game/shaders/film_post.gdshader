shader_type canvas_item;
// Full-screen film look applied to the 3D image, in this order:
//   1. snap to a pixel grid (cell size scales with the image height, so it looks the same at any RES),
//   2. grade: bloom, contrast, saturation, shadow/highlight tint, vignette, grain,
//   3. quantise colour to a few levels with an ordered (Bayer) dither.
// `fear` (0..1) drains colour, darkens the edges and thickens grain; `pixel_size`, `levels` and
// `dither_amount` are the dither/pixel filter and are driven by Film from one value.

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
uniform float pixel_size = 1.0;          // block size in pixels at 540p image height
uniform float levels = 256.0;            // colour levels per channel (256 = off)
uniform float dither_amount = 0.0;       // 0..1 strength of the Bayer pattern
uniform float pulse = 0.0;               // heartbeat throb of the vignette, 0..1
uniform float glitch = 0.0;              // 0..1 occasional horizontal tearing

const float BAYER[16] = float[16](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0);

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 sz = vec2(textureSize(TEXTURE, 0));
	float cell = max(1.0, round(pixel_size * sz.y / 540.0));
	vec2 grid = floor(UV * sz / cell);
	vec2 uv = (grid + 0.5) * cell / sz;

	float row = floor(UV.y * 48.0);
	float tear = step(0.965, hash21(vec2(row, floor(TIME * 7.0)))) * glitch;
	uv.x += tear * 0.025 * (hash21(vec2(row, 3.0)) - 0.5) * 2.0;

	vec2 d = uv - 0.5;
	float r2 = dot(d, d);
	vec2 off = d * fringe * (1.0 + fear * 2.0) * (0.4 + r2 * 4.0);
	vec3 col;
	col.r = texture(TEXTURE, uv + off).r;
	col.g = texture(TEXTURE, uv).g;
	col.b = texture(TEXTURE, uv - off).b;

	// Cheap bloom: a few wide taps of the bright parts (kept to the snapped grid).
	vec2 px = cell / sz;
	vec3 glow = vec3(0.0);
	for (int i = 0; i < 4; i++) {
		float a = 6.2831853 * (float(i) + 0.5) / 4.0;
		glow += max(texture(TEXTURE, uv + vec2(cos(a), sin(a)) * 5.0 * px).rgb - 0.55, 0.0);
	}
	col += glow * 0.25 * bloom;

	col *= exposure;
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = (col - 0.5) * contrast + 0.5;
	col = mix(vec3(l), col, saturation * (1.0 - fear * 0.55));
	col *= mix(shadow_tint, highlight_tint, smoothstep(0.1, 0.8, l));

	float v = vignette + fear * 0.35 + pulse * 0.12;
	vec2 dv = UV - 0.5;
	col *= 1.0 - v * smoothstep(0.18, 0.78, length(dv) * 1.55);

	float g = (hash21(grid + floor(TIME * 24.0) * 13.7) - 0.5) * (grain + fear * 0.05);
	col += g * (1.0 - 0.6 * l);

	// Ordered dither and colour quantisation, on the snapped grid.
	if (levels < 255.0) {
		ivec2 gi = ivec2(grid);
		float b = (BAYER[(gi.x & 3) + (gi.y & 3) * 4] + 0.5) / 16.0 - 0.5;
		float q = levels - 1.0;
		col = floor(clamp(col, 0.0, 1.0) * q + 0.5 + b * dither_amount) / q;
	}

	col *= 1.0 - blackout;
	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
