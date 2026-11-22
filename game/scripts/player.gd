class_name Player
extends CharacterBody3D
## First-person Martin. Input is pushed in from outside (touch controls),
## so the same body works with any control scheme.

const WALK_SPEED := 2.2
const GRAVITY := 9.8
const EYE_HEIGHT := 1.6
const REACH := 2.2
const PITCH_LIMIT := deg_to_rad(80.0)
const INTERACT_LAYER := 2

var shake := 0.0                 ## camera shake in metres (fear spikes)
var eye_drop := 0.0              ## how far the eyes are lowered (waking in bed)
var move_input := Vector2.ZERO   ## x = strafe right, y = back (screen-style: up is negative)
var head: Node3D
var camera: Camera3D
var _ray: RayCast3D
var _pitch := 0.0
var _walked := 0.0
var _bob_t := 0.0
var _sfx: Node


func _ready() -> void:
	_sfx = get_node_or_null("/root/Sfx")
	floor_snap_length = 0.6          # stay glued to stairs and ramps when walking down
	floor_max_angle = deg_to_rad(46.0)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.27
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = 0.85
	add_child(shape)

	head = Node3D.new()
	head.position.y = EYE_HEIGHT
	add_child(head)

	camera = Camera3D.new()
	camera.fov = 60.0
	camera.near = 0.05
	camera.far = 60.0
	head.add_child(camera)

	_ray = RayCast3D.new()
	_ray.target_position = Vector3(0, 0, -REACH)
	_ray.collision_mask = INTERACT_LAYER
	camera.add_child(_ray)


## Set the view direction directly (debug views and scripted moments): pitch in radians.
func set_pitch(pitch: float) -> void:
	_pitch = clampf(pitch, -PITCH_LIMIT, PITCH_LIMIT)
	head.rotation.x = _pitch


func look_by(relative: Vector2, sensitivity: float) -> void:
	rotate_y(-relative.x * sensitivity)
	_pitch = clampf(_pitch - relative.y * sensitivity, -PITCH_LIMIT, PITCH_LIMIT)
	head.rotation.x = _pitch


## The thing in reach that has an interact() method and a prompt, or null.
func target() -> CollisionObject3D:
	if _ray.is_colliding():
		var c := _ray.get_collider() as CollisionObject3D
		if c and c.has_method("interact"):
			return c
	return null


func _physics_process(delta: float) -> void:
	var dir := transform.basis * Vector3(move_input.x, 0.0, move_input.y)
	dir.y = 0.0
	if dir.length() > 1.0:
		dir = dir.normalized()
	velocity.x = dir.x * WALK_SPEED
	velocity.z = dir.z * WALK_SPEED
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	move_and_slide()
	var speed := Vector2(velocity.x, velocity.z).length()
	if speed > 0.4 and is_on_floor():
		_walked += speed * delta
		_bob_t += speed * delta * 3.2
		if _walked > 0.85:
			_walked = 0.0
			if _sfx:
				_sfx.call("play", "step_%d" % randi_range(0, 3), -16.0)
	else:
		_bob_t = lerpf(_bob_t, roundf(_bob_t / PI) * PI, 0.2)             # settle the bob when stopping
	var amp := clampf(speed / WALK_SPEED, 0.0, 1.0)
	head.position.y = EYE_HEIGHT - eye_drop + sin(_bob_t * 2.0) * 0.014 * amp
	camera.rotation.z = sin(_bob_t) * 0.0045 * amp
	camera.position = Vector3(randf_range(-shake, shake), randf_range(-shake, shake), 0.0) if shake > 0.0005 else Vector3.ZERO
