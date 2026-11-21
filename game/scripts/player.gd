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

var move_input := Vector2.ZERO   ## x = strafe right, y = back (screen-style: up is negative)
var head: Node3D
var camera: Camera3D
var _ray: RayCast3D
var _pitch := 0.0


func _ready() -> void:
	floor_snap_length = 0.6          # stay glued to stairs and ramps when walking down
	floor_max_angle = deg_to_rad(46.0)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = 0.85
	add_child(shape)

	head = Node3D.new()
	head.position.y = EYE_HEIGHT
	add_child(head)

	camera = Camera3D.new()
	camera.fov = 72.0
	camera.near = 0.05
	camera.far = 60.0
	head.add_child(camera)

	_ray = RayCast3D.new()
	_ray.target_position = Vector3(0, 0, -REACH)
	_ray.collision_mask = INTERACT_LAYER
	camera.add_child(_ray)


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
