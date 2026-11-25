class_name Atmosphere
## Time-of-day looks. Day 1 starts in daylight (overcast, pale, foggy); dusk and
## night come later in the story. Numbers are luminance-first: the dither shader
## only cares how bright things are, so each preset is tuned by brightness.

const PRESETS := {
	"day": {
		"sky": true, "sky_top": Color(0.40, 0.40, 0.40), "sky_horizon": Color(0.62, 0.62, 0.62),
		"cloud_bright": 0.80, "cloud_dark": 0.44, "cloud_cover": 0.72, "sky_glow": 0.0,
		"fog": Color(0.62, 0.62, 0.62), "fog_density": 0.022, "fog_sky": 0.35, "rain": 0.25,
		"ambient": Color(0.42, 0.42, 0.42), "light_dir": Vector3(-0.5, 0.5, 0.65), "light_energy": 1.0,
		"vignette": 0.18, "night": false, "beam": false, "porch": false, "sea_base": 0.24, "sea_glint": 0.22,
	},
	"dusk": {
		"sky": true, "sky_top": Color(0.10, 0.10, 0.10), "sky_horizon": Color(0.36, 0.36, 0.36),
		"cloud_bright": 0.42, "cloud_dark": 0.12, "cloud_cover": 0.7, "sky_glow": 0.5,
		"fog": Color(0.30, 0.30, 0.30), "fog_density": 0.018, "fog_sky": 0.4, "rain": 0.4,
		"ambient": Color(0.26, 0.26, 0.26), "light_dir": Vector3(-0.8, 0.22, -0.3), "light_energy": 0.6,
		"vignette": 0.35, "night": false, "beam": true, "porch": true, "sea_base": 0.16, "sea_glint": 0.35,
	},
	"night": {
		"sky": true, "sky_top": Color(0.02, 0.02, 0.02), "sky_horizon": Color(0.05, 0.05, 0.05),
		"cloud_bright": 0.20, "cloud_dark": 0.03, "cloud_cover": 0.75, "sky_glow": 1.0,
		"fog": Color(0.05, 0.05, 0.05), "fog_density": 0.016, "fog_sky": 0.2, "rain": 0.7,
		"ambient": Color(0.14, 0.14, 0.15), "light_dir": Vector3(-0.7, 0.5, -0.2), "light_energy": 0.35,
		"vignette": 0.55, "night": true, "beam": true, "porch": true, "sea_base": 0.10, "sea_glint": 0.45,
	},
}

const NAMES := ["day", "dusk", "night"]


## Returns the vignette strength for the post shader.
static func apply(name: String, env: Environment, sun: DirectionalLight3D, island: Island, lighthouse: Lighthouse) -> float:
	var p: Dictionary = PRESETS[name if PRESETS.has(name) else "day"]
	env.background_mode = Environment.BG_COLOR                      # the cloud dome (Island) draws the sky
	env.background_color = p["sky_horizon"]
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = p["ambient"]
	env.fog_enabled = true
	env.fog_light_color = p["fog"]
	env.fog_density = p["fog_density"]
	env.fog_sky_affect = p["fog_sky"]

	var dir: Vector3 = (p["light_dir"] as Vector3).normalized()      # direction TOWARD the light
	sun.transform = Transform3D(Basis.looking_at(-dir, Vector3.UP), Vector3.ZERO)
	sun.light_energy = p["light_energy"]
	sun.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY            # no sun disc in the sky

	island.set_sky(p)
	lighthouse.set_beam(p["beam"])
	island.set_sea(p["sea_base"], p["sea_glint"])
	lighthouse.set_porch(p["porch"])
	return p["vignette"]
