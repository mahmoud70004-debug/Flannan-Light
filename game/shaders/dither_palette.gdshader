shader_type canvas_item;
// Ordered (Bayer 4x4) dither of the low-res 3D image onto a small palette.
// Dither cells are low-res pixels, so the pattern stays crisp when upscaled.
// Before quantising: contrast curve, vignette and a luminance edge pass that
// darkens object outlines so shapes read at 240p.

uniform int levels = 4;
uniform vec3 c0 = vec3(0.0);
uniform vec3 c1 = vec3(0.3);
uniform vec3 c2 = vec3(0.6);
uniform vec3 c3 = vec3(0.9);
uniform vec3 c4 = vec3(1.0);
uniform vec3 c5 = vec3(1.0);
uniform float brightness = 1.0;
uniform float contrast = 1.25;
uniform float dither_amount = 0.5;
uniform int dither_cell = 1;
uniform float vignette = 0.55;
uniform float edge_strength = 0.8;
uniform float edge_threshold = 0.12;
uniform int mode = 0;                    // 0 = crunch (palette dither), 1 = photo (many tones, film grain, halation)
uniform float grain = 0.045;
uniform float halation = 0.45;
uniform int photo_levels = 24;

const float BAYER[16] = float[16](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0);

vec3 tone(int i) {
	if (i <= 0) return c0;
	if (i == 1) return c1;
	if (i == 2) return c2;
	if (i == 3) return c3;
	if (i == 4) return c4;
	return c5;
}

// Smooth ramp through the palette tones (photo mode).
vec3 ramp(float v) {
	float x = clamp(v, 0.0, 1.0) * float(levels - 1);
	int i = int(floor(x));
	return mix(tone(i), tone(min(i + 1, levels - 1)), x - float(i));
}

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

#define LUMA(uv) dot(texture(TEXTURE, (uv)).rgb, vec3(0.299, 0.587, 0.114))

void fragment() {
	vec2 px = 1.0 / vec2(textureSize(TEXTURE, 0));
	float l = LUMA(UV);
	float edge = abs(l - LUMA(UV + vec2(px.x, 0.0)))
		+ abs(l - LUMA(UV - vec2(px.x, 0.0)))
		+ abs(l - LUMA(UV + vec2(0.0, px.y)))
		+ abs(l - LUMA(UV - vec2(0.0, px.y)));

	float lum = l * brightness;
	if (mode == 1) {
		// Halation: bright areas bleed a little light into their surroundings, like old film.
		float bleed = 0.0;
		for (int k = 0; k < 4; k++) {
			vec2 o = vec2(k == 0 ? 3.0 : (k == 1 ? -3.0 : 0.0), k == 2 ? 3.0 : (k == 3 ? -3.0 : 0.0)) * px;
			bleed += max(LUMA(UV + o) - 0.62, 0.0);
		}
		lum += bleed * 0.25 * halation;
	}
	lum = (lum - 0.5) * contrast + 0.5;
	lum *= 1.0 - vignette * smoothstep(0.25, 0.85, length(UV - 0.5) * 1.6);
	lum *= 1.0 - edge_strength * smoothstep(edge_threshold, edge_threshold * 2.0, edge);
	lum = clamp(lum, 0.0, 1.0);

	ivec2 p = ivec2(UV * vec2(textureSize(TEXTURE, 0))) / max(dither_cell, 1);
	if (mode == 1) {
		float g = (hash21(vec2(p) + floor(TIME * 12.0) * 17.0) - 0.5) * grain;
		float t4 = (BAYER[(p.x % 4) + (p.y % 4) * 4] + 0.5) / 16.0 - 0.5;
		float q = float(photo_levels - 1);
		float v = clamp(lum + g, 0.0, 1.0) * q + t4 * dither_amount;
		COLOR = vec4(ramp(floor(v + 0.5) / q), 1.0);
	} else {
		float threshold = (BAYER[(p.x % 4) + (p.y % 4) * 4] + 0.5) / 16.0;
		threshold = mix(0.5, threshold, dither_amount);
		float v = lum * float(levels - 1);
		float lo = floor(v);
		int idx = int(lo) + ((v - lo) > threshold ? 1 : 0);
		idx = clamp(idx, 0, levels - 1);
		COLOR = vec4(tone(idx), 1.0);
	}
}
