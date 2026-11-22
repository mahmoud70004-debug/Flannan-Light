class_name Stranger
extends Node3D
## The figure Martin keeps seeing: tall, thin, in the same grey hoodie and jeans as Martin, with a
## smooth blank face. It only ever stands still, and it only moves when it is not being looked at:
## it shows up out of the corner of the eye, creeps a step closer each time the player looks away,
## and is gone when stared at too long or approached. It never touches or chases. Its pose is
## updated at 12 fps (stop-motion) so it never moves smoothly.

signal vanished(by_gaze: bool)
signal first_seen

enum State { HIDDEN, WAITING, WATCHED }

const WATCH_LIMIT := 2.2          ## seconds of being stared at before it is gone
const GONE_WITHIN := 1.9          ## metres: it vanishes if the player gets this close
const GIVE_UP := 28.0             ## seconds unseen before it leaves quietly

var state := State.HIDDEN
var revealed := false
var player: Player
var apartment: Apartment
var final_mode := false           ## the last scene: it stays, and never vanishes or creeps
var approach_step := 0.9          ## how far it creeps toward the player each time they look away

var _head: Node3D
var _torso: Node3D
var _parts: Array[MeshInstance3D] = []
var _tick := 0.0
var _watch := 0.0
var _unseen := 0.0
var _wait := 0.0
var _was_seen := false
var _body: Interactable
var _face_parts: Array[Node] = []


func _ready() -> void:
	visible = false
	_build()


func _part(parent: Node3D, mesh: Mesh, pos: Vector3, mat_key: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = Mats.get_mat(mat_key)
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	_parts.append(mi)
	return mi


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _build() -> void:
	for sx in [-1.0, 1.0]:
		_part(self, _box(Vector3(0.14, 0.92, 0.15)), Vector3(sx * 0.1, 0.46, 0), "cloth_blue")        # legs
		_part(self, _box(Vector3(0.12, 0.05, 0.26)), Vector3(sx * 0.1, 0.025, -0.05), "black")          # shoes
	_torso = Node3D.new()
	_torso.position = Vector3(0, 0.92, 0)
	add_child(_torso)
	_part(_torso, _box(Vector3(0.44, 0.66, 0.23)), Vector3(0, 0.33, 0), "cloth_grey")                   # the hoodie
	for sx in [-1.0, 1.0]:
		_part(_torso, _box(Vector3(0.09, 0.9, 0.1)), Vector3(sx * 0.28, 0.2, 0), "cloth_grey")          # long arms
		_part(_torso, _box(Vector3(0.09, 0.12, 0.1)), Vector3(sx * 0.28, -0.3, 0), "skin")              # hands
	_head = Node3D.new()
	_head.position = Vector3(0, 0.74, 0)
	_torso.add_child(_head)
	_part(_head, CylinderMesh.new(), Vector3(0, 0.0, 0), "skin")
	(_parts[-1].mesh as CylinderMesh).top_radius = 0.045
	(_parts[-1].mesh as CylinderMesh).bottom_radius = 0.05
	(_parts[-1].mesh as CylinderMesh).height = 0.14
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.28
	sphere.radial_segments = 14
	sphere.rings = 8
	var skull := _part(_head, sphere, Vector3(0, 0.17, 0), "skin")
	skull.scale = Vector3(0.95, 1.12, 0.95)
	# Hood up behind the head
	_part(_torso, _box(Vector3(0.36, 0.14, 0.1)), Vector3(0, 0.7, 0.1), "cloth_grey")
	_body = Interactable.new()
	_body.prompt = "..."
	_body.collision_layer = 0
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.9, 1.9, 0.9)
	shape.shape = bs
	shape.position = Vector3(0, 0.95, 0)
	_body.add_child(shape)
	add_child(_body)


## The interaction body, so the game can listen for the player facing it at the end.
func body() -> Interactable:
	return _body


func set_interactive(on: bool) -> void:
	_body.collision_layer = 2 if on else 0


func _set_layers(mask: int) -> void:
	for p in _parts:
		p.layers = mask
	for f in _face_parts:
		(f as MeshInstance3D).layers = mask


## Shows it at `pos` (on the floor), turned to face the player.
func place(pos: Vector3) -> void:
	position = pos
	_set_layers(apartment.layer_of(apartment.cell_at(pos)) | Apartment.L_JAMB)
	_face_player()
	visible = true
	state = State.WAITING
	_watch = 0.0
	_unseen = 0.0
	_wait = 0.0
	_was_seen = false


func vanish(by_gaze := false) -> void:
	if state == State.HIDDEN:
		return
	final_mode = false
	state = State.HIDDEN
	visible = false
	set_interactive(false)
	vanished.emit(by_gaze)


func _face_player() -> void:
	var d := player.global_position - global_position
	rotation.y = atan2(-d.x, -d.z)            # its front (local -Z) toward the player


func head_position() -> Vector3:
	return global_position + Vector3(0, 1.75, 0)


## True if the player can see its head right now: in the camera frustum with nothing in between.
func is_seen() -> bool:
	if state == State.HIDDEN or player == null:
		return false
	var cam := player.camera
	var hp := head_position()
	if not cam.is_position_in_frustum(hp) or cam.global_position.distance_to(hp) > 16.0:
		return false
	var q := PhysicsRayQueryParameters3D.create(cam.global_position, hp)
	q.collision_mask = 1
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func distance_to_player() -> float:
	return Vector2(global_position.x - player.global_position.x, global_position.z - player.global_position.z).length()


func _process(delta: float) -> void:
	if state == State.HIDDEN or player == null:
		return
	# Stop-motion: the pose only changes twelve times a second.
	_tick += delta
	if _tick >= 1.0 / 12.0:
		_tick = 0.0
		_head.rotation.z = deg_to_rad(randf_range(-6.0, 6.0) + 12.0)         # the head sits a little tilted
		_head.rotation.x = deg_to_rad(randf_range(-2.0, 4.0))
		_torso.rotation.z = deg_to_rad(randf_range(-1.5, 1.5))
	if final_mode:
		_face_player()
		return
	if distance_to_player() < GONE_WITHIN and not revealed:
		vanish(true)
		return
	var seen := is_seen()
	match state:
		State.WAITING:
			_wait += delta
			if seen:
				state = State.WATCHED
				_watch = 0.0
				first_seen.emit()
			elif _wait > GIVE_UP:
				vanish(false)
		State.WATCHED:
			if seen:
				_watch += delta
				_unseen = 0.0
				if _watch > WATCH_LIMIT and not revealed:
					vanish(true)
			else:
				_unseen += delta
				if _unseen > 0.35:                      # the player looked away: it creeps closer
					_unseen = 0.0
					state = State.WAITING
					_wait = 0.0
					var d := player.global_position - global_position
					d.y = 0.0
					if d.length() > 2.6 and approach_step > 0.0:
						var np := global_position + d.normalized() * minf(approach_step, d.length() - 2.4)
						if apartment.cell_at(np) != "":
							global_position = np
							_set_layers(apartment.layer_of(apartment.cell_at(np)) | Apartment.L_JAMB)
					_face_player()


## The end: the face is Martin's own.
func reveal_as_martin() -> void:
	revealed = true
	var eye := SphereMesh.new()
	eye.radius = 0.018
	eye.height = 0.036
	eye.radial_segments = 8
	eye.rings = 4
	for sx in [-1.0, 1.0]:
		var e := MeshInstance3D.new()
		e.mesh = eye
		e.material_override = Mats.get_mat("black")
		e.position = Vector3(sx * 0.045, 0.2, -0.108)
		_head.add_child(e)
		_face_parts.append(e)
	var mouth := MeshInstance3D.new()
	mouth.mesh = _box(Vector3(0.07, 0.01, 0.01))
	mouth.material_override = Mats.get_mat("rot")
	mouth.position = Vector3(0, 0.1, -0.113)
	_head.add_child(mouth)
	_face_parts.append(mouth)
	_head.rotation.z = 0.0
