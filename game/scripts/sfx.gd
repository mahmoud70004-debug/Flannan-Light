extends Node
## Sound player (autoload "Sfx"): one-shots, positional one-shots and loops. Sounds are looked up by
## name in Audio. When Audio.muted is set (tests) every call does nothing and returns null.

## The node 3D sounds are added under (the world sets it).
var world: Node3D
var master_db := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func set_volume(linear: float) -> void:
	master_db = linear_to_db(clampf(linear, 0.0, 1.0)) if linear > 0.001 else -80.0
	AudioServer.set_bus_volume_db(0, master_db)


## A flat (non-positional) one-shot, e.g. UI, voice, heartbeat.
func play(sound: String, volume_db := 0.0) -> AudioStreamPlayer:
	var s := Audio.stream(sound)
	if Audio.muted or s == null:
		return null
	var p := AudioStreamPlayer.new()
	p.stream = s
	p.volume_db = volume_db
	p.finished.connect(p.queue_free)
	add_child(p)
	p.play()
	return p


## A one-shot from a place in the world; louder up close, fading out by `max_dist`.
func play_at(sound: String, pos: Vector3, volume_db := 0.0, max_dist := 14.0, unit := 2.5) -> AudioStreamPlayer3D:
	var s := Audio.stream(sound)
	if Audio.muted or s == null or world == null:
		return null
	var p := AudioStreamPlayer3D.new()
	p.stream = s
	p.volume_db = volume_db
	p.max_distance = max_dist
	p.unit_size = unit
	p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	p.finished.connect(p.queue_free)
	world.add_child(p)
	p.position = pos
	p.play()
	return p


## A looping flat sound that stays until stop() is called on it.
func loop(sound: String, volume_db := 0.0) -> AudioStreamPlayer:
	var s := Audio.stream(sound)
	if Audio.muted or s == null:
		return null
	var p := AudioStreamPlayer.new()
	p.stream = s
	p.volume_db = volume_db
	add_child(p)
	p.play()
	return p


## A looping positional sound (a dripping tap, the fridge).
func loop_at(sound: String, pos: Vector3, volume_db := 0.0, max_dist := 10.0, unit := 2.0) -> AudioStreamPlayer3D:
	var s := Audio.stream(sound)
	if Audio.muted or s == null or world == null:
		return null
	var p := AudioStreamPlayer3D.new()
	p.stream = s
	p.volume_db = volume_db
	p.max_distance = max_dist
	p.unit_size = unit
	world.add_child(p)
	p.position = pos
	p.play()
	return p


## Fades a playing sound out and releases it (a cut-off loop makes an audible click).
func fade_stop(p: Node, seconds := 0.35) -> void:
	if p == null or not is_instance_valid(p):
		return
	var tw := create_tween()
	tw.tween_property(p, "volume_db", -60.0, seconds)
	tw.tween_callback(func() -> void: stop(p))


func stop(p: Node) -> void:
	if p and is_instance_valid(p):
		(p as Object).call("stop")
		p.queue_free()


## Releases every playing sound (scene changes, quitting).
func clear() -> void:
	for c in get_children():
		if c is AudioStreamPlayer:
			(c as AudioStreamPlayer).stop()
			c.queue_free()
