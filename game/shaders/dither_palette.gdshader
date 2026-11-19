shader_type canvas_item;
// Ordered (Bayer 4x4) dither of the low-res 3D image onto a small palette.
// Dither cells are low-res pixels, so the pattern stays crisp when upscaled.

uniform int levels = 4;
uniform vec3 c0 = vec3(0.0);
uniform vec3 c1 = vec3(0.3);
uniform vec3 c2 = vec3(0.6);
uniform vec3 c3 = vec3(0.9);
uniform vec3 c4 = vec3(1.0);
uniform vec3 c5 = vec3(1.0);
uniform float brightness = 1.0;
uniform float dither_amount = 1.0;

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

void fragment() {
	vec3 src = texture(TEXTURE, UV).rgb;
	float lum = clamp(dot(src, vec3(0.299, 0.587, 0.114)) * brightness, 0.0, 1.0);
	ivec2 size = textureSize(TEXTURE, 0);
	ivec2 p = ivec2(UV * vec2(size));
	float threshold = (BAYER[(p.x % 4) + (p.y % 4) * 4] + 0.5) / 16.0;
	threshold = mix(0.5, threshold, dither_amount);
	float v = lum * float(levels - 1);
	float lo = floor(v);
	int idx = int(lo) + ((v - lo) > threshold ? 1 : 0);
	idx = clamp(idx, 0, levels - 1);
	COLOR = vec4(tone(idx), 1.0);
}
