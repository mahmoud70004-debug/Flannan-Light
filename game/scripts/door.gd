class_name Door
extends AnimatableBody3D
## A hinged door. The node origin is the hinge; mesh and collision hang off it
## to one side. Interact toggles it with a heavy ease; collision rotates with it.

signal toggled(is_open: bool)

@export var open_angle := 100.0   ## degrees, positive swings the free edge toward -Z
@export var open_time := 0.85
@export var close_time := 0.7

var prompt := "Open door"
var is_open := false
var _tween: Tween


func interact() -> void:
	set_open(not is_open)


func set_open(value: bool, animate := true) -> void:
	is_open = value
	prompt = "Close door" if is_open else "Open door"
	var target := open_angle if is_open else 0.0
	if _tween:
		_tween.kill()
	if not animate:
		rotation_degrees.y = target
	else:
		_tween = create_tween()
		if is_open:
			_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_tween.tween_property(self, "rotation_degrees:y", target, open_time)
		else:
			_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
			_tween.tween_property(self, "rotation_degrees:y", target, close_time)
	toggled.emit(is_open)
