class_name Player
extends CharacterBody3D
## First-person keeper. Input is pushed in from outside (touch controls),
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
var lantern_light: OmniLight3D       ## the keeper's hand lantern: the only warm light in the world
var _lantern: Node3D
var _lantern_t := 0.0


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
	camera.near = 0.12                       # depth precision on phones: no shimmering coplanar surfaces
	camera.far = 320.0
	head.add_child(camera)

	_ray = RayCast3D.new()
	_ray.target_position = Vector3(0, 0, -REACH)
	_ray.collision_mask = INTERACT_LAYER | 1                 # walls block it: nothing is used through a wall
	camera.add_child(_ray)
	_build_lantern()


## A storm lantern held low in the right hand: a small frame with a warm glass, and a short-ranged warm light.
func _build_lantern() -> void:
	_lantern = Node3D.new()
	_lantern.position = Vector3(0.34, -0.42, -0.72)
	_lantern.scale = Vector3.ONE * 0.85
	camera.add_child(_lantern)
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.08, 0.08, 0.08)
	var glass := StandardMaterial3D.new()
	glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glass.albedo_color = Color(1.0, 0.7, 0.36)
	var parts := [[Vector3(0.09, 0.012, 0.09), Vector3(0, 0.075, 0), iron], [Vector3(0.1, 0.018, 0.1), Vector3(0, -0.07, 0), iron],
		[Vector3(0.06, 0.12, 0.06), Vector3.ZERO, glass], [Vector3(0.01, 0.05, 0.01), Vector3(0, 0.105, 0), iron]]
	for cx in [-0.034, 0.034]:                           # the wire guard in front of the glass
		for cz in [-0.034, 0.034]:
			parts.append([Vector3(0.008, 0.13, 0.008), Vector3(cx, 0, cz), iron])
	for p in parts:
		var mi := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = p[0]
		mi.mesh = b
		mi.position = p[1]
		mi.material_override = p[2]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_lantern.add_child(mi)
	lantern_light = OmniLight3D.new()
	lantern_light.light_color = Color(1.0, 0.62, 0.3)
	lantern_light.omni_range = 3.4
	lantern_light.omni_attenuation = 1.6
	lantern_light.light_energy = 2.4
	lantern_light.position = Vector3(0, 0.02, 0)
	_lantern.add_child(lantern_light)
	set_lantern(false)


func set_lantern(on: bool) -> void:
	_lantern.visible = on
	lantern_light.visible = on


func lantern_on() -> bool:
	return _lantern.visible


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


func _process(delta: float) -> void:
	if _lantern.visible:                                  # the flame breathes
		_lantern_t += delta
		lantern_light.light_energy = 2.4 * (1.0 + 0.06 * sin(_lantern_t * 8.0) + 0.04 * sin(_lantern_t * 21.0 + 1.3))
		_lantern.position.y = -0.42 + sin(_lantern_t * 2.1) * 0.006


func _physics_process(delta: float) -> void:
	var dir := transform.basis * Vector3(move_input.x, 0.0, move_input.y)
	dir.y = 0.0
	if dir.length() > 1.0:
		dir = dir.normalized()
	velocity.x = dir.x * WALK_SPEED
	velocity.z = dir.z * WALK_SPEED
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	move_and_slide()
