class_name DoorCatch
extends StaticBody3D
## Fills the doorway on the interaction layer only (never blocks walking), so an
## open door can be closed by aiming at the opening, not just at the leaf.

var door: Door

var prompt: String:
	get:
		return door.prompt if door else ""


func interact() -> void:
	if door:
		door.interact()
