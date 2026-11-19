extends SceneTree
## Headless smoke test: run with
##   godot --headless --path game --script res://tests/smoke.gd
## Exits 1 on the first failure. Cannot judge rendering (no GPU), only that
## scripts, scenes and data are sound.

var _failed := false


func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		_failed = true


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# Palettes
	_check(Palettes.count() >= 2, "palettes exist")
	for i in Palettes.count():
		var cols := Palettes.colors(i)
		_check(cols.size() >= 2 and cols.size() <= Palettes.MAX_TONES, "palette %s has 2..%d tones" % [Palettes.preset_name(i), Palettes.MAX_TONES])

	# Shader compiles into a material
	var shader := load("res://shaders/dither_palette.gdshader") as Shader
	_check(shader != null, "dither shader loads")

	# Scenes instantiate and survive a few frames
	for path in ["res://scenes/title.tscn", "res://scenes/world.tscn"]:
		var packed := load(path) as PackedScene
		_check(packed != null, "%s loads" % path)
		if packed:
			var inst := packed.instantiate()
			root.add_child(inst)
			await process_frame
			await process_frame
			_check(is_instance_valid(inst), "%s runs two frames" % path)
			inst.queue_free()
			await process_frame

	# Settings round-trip
	var s := root.get_node_or_null("Settings")
	_check(s != null, "Settings autoload present")
	if s:
		s.palette = 2
		s.save()
		_check(FileAccess.file_exists("user://settings.cfg"), "settings file written")
		s.palette = 0
		s.save()

	quit(1 if _failed else 0)
