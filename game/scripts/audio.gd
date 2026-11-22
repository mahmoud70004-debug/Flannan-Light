class_name Audio
## Sound lookup shared by everything that makes noise. Tests set `muted` so nothing is played
## (the headless audio driver never releases playbacks, which makes the engine complain at exit).

const LOOPS := ["flies_loop", "room_tone", "fridge_hum", "drone", "heartbeat", "drip", "street"]

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
