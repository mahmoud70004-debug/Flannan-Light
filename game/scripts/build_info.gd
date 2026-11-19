extends Node
## Build number and commit, written into res://build_info.json by CI.
## Shown on the title screen so you can tell which build you are looking at.

var build: String = "dev"
var commit: String = "local"


func _ready() -> void:
	var path := "res://build_info.json"
	if not FileAccess.file_exists(path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary:
		build = str(data.get("build", build))
		commit = str(data.get("commit", commit))


func label() -> String:
	return "build %s · %s" % [build, commit]
