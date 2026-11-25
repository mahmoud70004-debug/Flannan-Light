class_name WeatherSound
extends Node
## The island's weather heard: the sea against the rocks, the wind, the rain. Each loop's level follows where the
## keeper is: full outdoors, muffled and low under the tower (the store), and the rain only when it rains.

var _sea: AudioStreamPlayer
var _wind: AudioStreamPlayer
var _rain: AudioStreamPlayer
var rain := 0.3                    ## 0..1, from the time-of-day preset
var underground := false
var _muffle := 0.0


func _ready() -> void:
	_sea = Sfx.loop("sea", -80.0)
	_wind = Sfx.loop("wind", -80.0)
	_rain = Sfx.loop("rain", -80.0)


func _process(delta: float) -> void:
	_muffle = move_toward(_muffle, 1.0 if underground else 0.0, delta * 1.5)
	var m := lerpf(0.0, -18.0, _muffle)
	if _sea:
		_sea.volume_db = -6.0 + m
	if _wind:
		_wind.volume_db = -11.0 + m * 1.2
	if _rain:
		_rain.volume_db = (linear_to_db(maxf(rain, 0.001)) - 4.0) + m * 1.3


func _exit_tree() -> void:
	for p in [_sea, _wind, _rain]:
		if p and is_instance_valid(p):
			Sfx.stop(p)
