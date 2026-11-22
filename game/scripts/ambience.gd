class_name Ambience
extends Node
## The flat's background sound: room tone, the street far away, the fridge, a dripping tap, and two
## layers that follow the story's fear value (a low drone, and a heartbeat that comes in when
## things are bad). Everything can be hushed for a few seconds: silence is the scare.

var _tone: AudioStreamPlayer
var _street: AudioStreamPlayer
var _drone: AudioStreamPlayer
var _heart: AudioStreamPlayer
var _fridge: AudioStreamPlayer3D
var _drip: AudioStreamPlayer3D
var _tick: AudioStreamPlayer3D
var _wind: AudioStreamPlayer
var _tick_on := true
var _hush := 0.0                 ## seconds of silence left
var _hush_amount := 0.0          ## 0..1 how much the background is pulled down
var _level := 1.0


func setup(apartment: Apartment) -> void:
	_tone = Sfx.loop("room_tone", -22.0)
	_street = Sfx.loop("street", -30.0)
	_drone = Sfx.loop("drone", -60.0)
	_heart = Sfx.loop("heartbeat", -60.0)
	_fridge = Sfx.loop_at("fridge_hum", Vector3(4.4, 1.0, -0.5), -10.0, 9.0, 1.5)
	_drip = Sfx.loop_at("drip", Vector3(-5.2, 0.8, -2.2), -12.0, 7.0, 1.0)
	_tick = Sfx.loop_at("tick", Vector3(-0.85, 1.95, -7.0), -9.0, 7.0, 1.2)
	_wind = Sfx.loop("wind", -34.0)


## From day 5 the wall clock stops ticking: it says 3:07 and the room is quieter for it.
func set_day(day: int) -> void:
	_tick_on = day < 5
	if _tick:
		_tick.stream_paused = not _tick_on


## Silence the background for `seconds`; `amount` 1 is total silence.
func hush(seconds: float, amount := 1.0) -> void:
	_hush = seconds
	_hush_amount = amount


func update(delta: float, fear: float) -> void:
	_hush = maxf(_hush - delta, 0.0)
	var target := 1.0 - (_hush_amount if _hush > 0.0 else 0.0)
	_level = move_toward(_level, target, delta * (6.0 if target < _level else 0.5))      # drops fast, returns slowly
	var db := linear_to_db(maxf(_level, 0.001))
	if _tone:
		_tone.volume_db = -22.0 + db
	if _street:
		_street.volume_db = -30.0 + db
	if _fridge:
		_fridge.volume_db = -10.0 + db
	if _drip:
		_drip.volume_db = -12.0 + db
	if _tick:
		_tick.volume_db = -9.0 + db
	if _wind:
		_wind.volume_db = -34.0 + db
	if _drone:
		_drone.volume_db = lerpf(-60.0, -15.0, pow(clampf(fear, 0.0, 1.0), 1.4))
	if _heart:
		_heart.volume_db = lerpf(-60.0, -14.0, clampf((fear - 0.45) / 0.55, 0.0, 1.0))


func stop_all() -> void:
	for p in [_tone, _street, _drone, _heart, _wind]:
		Sfx.stop(p)
	for p in [_fridge, _drip, _tick]:
		if p and is_instance_valid(p):
			p.stop()
			p.queue_free()
	_tone = null
	_street = null
	_drone = null
	_heart = null
	_fridge = null
	_drip = null
	_tick = null
	_wind = null
