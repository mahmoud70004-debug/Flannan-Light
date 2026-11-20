class_name Atmosphere
## Time-of-day looks. Day 1 starts in daylight (overcast, pale, foggy); dusk and
## night come later in the story. Numbers are luminance-first: the dither shader
## only cares how bright things are, so each preset is tuned by brightness.

const PRESETS := {
	"day": {
		"sky": true, "sky_top": Color(0.36, 0.38, 0.41), "sky_horizon": Color(0.56, 0.58, 0.60),
		"fog": Color(0.56, 0.58, 0.60), "fog_density": 0.013, "fog_sky": 0.35,
		"ambient": Color(0.40, 0.42, 0.45), "light_dir": Vector3(-0.5, 0.5, 0.65), "light_energy": 1.1,
		"vignette": 0.12, "night": false, "beam": false, "porch": false, "sea_base": 0.24, "sea_glint": 0.22,
	},
	"dusk": {
		"sky": true, "sky_top": Color(0.10, 0.11, 0.13), "sky_horizon": Color(0.38, 0.39, 0.41),
		"fog": Color(0.30, 0.31, 0.33), "fog_density": 0.015, "fog_sky": 0.4,
		"ambient": Color(0.26, 0.27, 0.30), "light_dir": Vector3(-0.8, 0.22, -0.3), "light_energy": 0.6,
		"vignette": 0.35, "night": false, "beam": true, "porch": true, "sea_base": 0.16, "sea_glint": 0.35,
	},
	"night": {
		"sky": false, "sky_top": Color.BLACK, "sky_horizon": Color.BLACK,
		"fog": Color.BLACK, "fog_density": 0.011, "fog_sky": 1.0,
		"ambient": Color(0.20, 0.20, 0.22), "light_dir": Vector3(-0.7, 0.5, -0.2), "light_energy": 1.3,
		"vignette": 0.55, "night": true, "beam": true, "porch": true, "sea_base": 0.12, "sea_glint": 0.55,
	},
}

const NAMES := ["day", "dusk", "night"]


## Returns the vignette strength for the post shader.
static func apply(name: String, env: Environment, sun: DirectionalLight3D, island: Island, lighthouse: Lighthouse) -> float:
	var p: Dictionary = PRESETS[name if PRESETS.has(name) else "day"]
	if p["sky"]:
		var sky_mat := ProceduralSkyMaterial.new()
		sky_mat.sky_top_color = p["sky_top"]
		sky_mat.sky_horizon_color = p["sky_horizon"]
		sky_mat.ground_horizon_color = p["sky_horizon"]
		sky_mat.ground_bottom_color = p["sky_horizon"]
		sky_mat.sky_curve = 0.25
		sky_mat.sun_angle_max = 0.0
		var sky := Sky.new()
		sky.sky_material = sky_mat
		env.sky = sky
		env.background_mode = Environment.BG_SKY
	else:
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color.BLACK
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

	island.set_night_sky(p["night"], dir)
	lighthouse.set_beam(p["beam"])
	island.set_sea(p["sea_base"], p["sea_glint"])
	lighthouse.set_porch(p["porch"])
	return p["vignette"]
