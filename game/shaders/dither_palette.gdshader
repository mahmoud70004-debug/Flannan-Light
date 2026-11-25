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
uniform float rain = 0.0;                // screen-space rain streaks, 0 = none
uniform vec3 warm_tint = vec3(1.2, 0.9, 0.62);   // the hand lantern: the only colour in the world
uniform float warm_gain = 1.0;

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

// Thin slanted streaks falling across the picture, two layers (near and far).
float rain_at(vec2 uv, float t) {
	float r = 0.0;
	for (int layer = 0; layer < 2; layer++) {
		float cols = layer == 0 ? 90.0 : 170.0;
		float speed = layer == 0 ? 2.6 : 1.7;
		vec2 q = uv;
		q.x += q.y * 0.18;                                  // the wind slants the rain
		float col = floor(q.x * cols);
		float h = hash21(vec2(col, float(layer) * 7.0));
		float y = fract(q.y * (layer == 0 ? 1.4 : 2.2) - t * speed - h * 9.0);
		float len = layer == 0 ? 0.07 : 0.04;
		float on = step(0.72, h) * smoothstep(0.0, 0.02, y) * (1.0 - smoothstep(len * 0.5, len, y));
		float thin = 1.0 - smoothstep(0.0, 0.18, abs(fract(q.x * cols) - 0.5));
		r += on * thin * (layer == 0 ? 0.45 : 0.25);
	}
	return r;
}

void fragment() {
	vec2 px = 1.0 / vec2(textureSize(TEXTURE, 0));
	vec3 src = texture(TEXTURE, UV).rgb;
	// Every material in the world is grey; only the hand lantern's light is warm. Whatever warmth reaches the
	// picture came from it, and it is put back on top of the dithered grey below.
	float warm = clamp(((src.r - src.b) - 0.05) * 3.5, 0.0, 1.0) * warm_gain;
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
	if (rain > 0.0) {
		lum += rain_at(UV, TIME) * rain;
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
		COLOR = vec4(ramp(floor(v + 0.5) / q) * mix(vec3(1.0), warm_tint, warm), 1.0);
	} else {
		float threshold = (BAYER[(p.x % 4) + (p.y % 4) * 4] + 0.5) / 16.0;
		threshold = mix(0.5, threshold, dither_amount);
		float v = lum * float(levels - 1);
		float lo = floor(v);
		int idx = int(lo) + ((v - lo) > threshold ? 1 : 0);
		idx = clamp(idx, 0, levels - 1);
		COLOR = vec4(tone(idx) * mix(vec3(1.0), warm_tint, warm), 1.0);
	}
}
