class_name Flies
extends Node3D
## A swarm of flies over something rotten: one mesh of tiny black billboards that the GPU moves
## around a point (no per-frame script), plus a positional buzz that gets loud as you come close.
## `intensity` (0..1) scales how many flies show and how loud they are, so the story can make a
## room worse day by day.

const SHADER := preload("res://shaders/flies.gdshader")

var _mat: ShaderMaterial
var _audio: AudioStreamPlayer3D
var intensity := 1.0:
	set(v):
		intensity = clampf(v, 0.0, 1.0)
		if _mat:
			_mat.set_shader_parameter("amount", intensity)
		if _audio:
			_audio.volume_db = lerpf(-30.0, -3.0, intensity)
			if intensity <= 0.01 and _audio.playing:
				_audio.stop()
			elif intensity > 0.01 and not _audio.playing and is_inside_tree():
				_audio.play()


func _exit_tree() -> void:
	if _audio:
		_audio.stop()                            # release the playback so the audio server lets go of the stream


## Builds a swarm at `pos` (in the parent's space). `layer` is the visual layer of the room.
static func make(parent: Node3D, layer: int, pos: Vector3, count := 14, radius := 0.28) -> Flies:
	var f := Flies.new()
	f.position = pos
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(pos.x * 100.0) * 31 + int(pos.z * 100.0)
	for i in count:
		var seed_col := Color(rng.randf(), rng.randf(), rng.randf(), float(i) / float(count))
		var corners := [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_color(seed_col)
			st.set_uv(corners[k])
			st.add_vertex(Vector3.ZERO)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.custom_aabb = AABB(Vector3(-radius, -radius, -radius), Vector3.ONE * radius * 2.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.layers = layer
	f._mat = ShaderMaterial.new()
	f._mat.shader = SHADER
	f._mat.set_shader_parameter("radius", radius)
	mi.material_override = f._mat
	f.add_child(mi)
	f.set_meta("mesh", mi)

	if not Audio.muted:
		f._audio = AudioStreamPlayer3D.new()
		f._audio.stream = Audio.stream("flies_loop")
		f._audio.unit_size = 1.2
		f._audio.max_distance = 7.0
		f._audio.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
		f._audio.volume_db = -3.0
		f.add_child(f._audio)
	parent.add_child(f)
	if f._audio:
		f._audio.play()
	return f
