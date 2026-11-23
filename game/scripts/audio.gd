class_name Audio
## Sound lookup shared by everything that makes noise. Tests set `muted` so nothing is played
## (the headless audio driver never releases playbacks, which makes the engine complain at exit).

const LOOPS := ["tap_run", "dial_tone", "flies_loop", "room_tone", "fridge_hum", "drone", "heartbeat", "drip", "street", "phone_ring", "tv_static", "tick", "wind"]

static var muted := false
static var _cache := {}


## The stream called `name` from res://assets/audio (without extension), or null.
static func stream(name: String) -> AudioStream:
	if _cache.has(name):
		return _cache[name]
	var path := "res://assets/audio/%s.ogg" % name
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path)
		if s is AudioStreamOggVorbis:
			(s as AudioStreamOggVorbis).loop = name in LOOPS
	_cache[name] = s
	return s


static func length(name: String) -> float:
	var s := stream(name)
	return s.get_length() if s else 0.0


## Loads every sound now (call it behind a black screen): the first play of a sound otherwise stalls a frame.
static func warm() -> void:
	var dir := DirAccess.open("res://assets/audio")
	if dir == null:
		return
	for f in dir.get_files():
		var n := f
		if n.ends_with(".import"):
			n = n.trim_suffix(".import")
		if n.ends_with(".ogg"):
			stream(n.trim_suffix(".ogg"))
