class_name Interactable
extends StaticBody3D
## Something the player can use with the Interact button.

signal interacted

@export var prompt: String = "Use"


func interact() -> void:
	interacted.emit()
