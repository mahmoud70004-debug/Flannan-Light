class_name RoomKit
extends Node3D
## Shared building blocks for the game's interiors: merged static visuals (one draw
## call per material and layer), solid slabs with collision, interactables and doors.
## Interior visuals live on layer 2 (lit by the room's own lights); the outdoors lives
## on layer 1 (lit by sun or moon). Layers keep daylight out of the rooms.

var _stone: StandardMaterial3D
var _wood: StandardMaterial3D
var _dark_wood: StandardMaterial3D
var _sack: StandardMaterial3D
var _iron: StandardMaterial3D
var _plaster: StandardMaterial3D
var _batches := {}                ## [Material, layer] -> SurfaceTool


func _init_materials() -> void:
	_stone = Tex.material(Tex.bricks(), 1.0)
	_wood = Tex.material(Tex.planks(), 1.0)
	_dark_wood = Tex.material(Tex.planks(), 1.0, 0.55)
	_sack = Tex.material(Tex.burlap(), 0.5)
	_iron = Tex.material(Tex.rough(), 1.0, 0.8)
	_plaster = Tex.material(Tex.plaster(), 2.0, 0.85)


func _batch(mesh: Mesh, xform: Transform3D, mat: Material, layer := 2) -> void:
	var key := [mat, layer]
	if not _batches.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_batches[key] = st
	(_batches[key] as SurfaceTool).append_from(mesh, 0, xform)


func _flush_batches() -> void:
	for key in _batches:
		var st: SurfaceTool = _batches[key]
		st.generate_tangents()
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = key[0]
		mi.layers = key[1]
		add_child(mi)
	_batches.clear()


func _solid(size: Vector3, pos: Vector3, mat: Material, basis := Basis()) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.transform = Transform3D(basis, pos)
	var box := BoxMesh.new()
	box.size = size
	_batch(box, Transform3D(basis, pos), mat)
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)
	add_child(body)
	return body


func _prop_box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var box := BoxMesh.new()
	box.size = size
	_batch(box, Transform3D(Basis(), pos), mat)


func _interactable(label: String, size: Vector3, pos: Vector3) -> Interactable:
	var body := Interactable.new()
	body.prompt = label
	body.collision_layer = 2
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)
	body.position = pos
	add_child(body)
	return body


## A hinged door with an interaction catch in its opening. `hinge` is the bottom of the
## hinge edge; the leaf swings toward -Z (into the room) when opened.
func make_door(width: float, height: float, hinge: Vector3, parent: Node3D = null) -> Door:
	if parent == null:
		parent = self
	var d := Door.new()
	d.collision_layer = 1 | 2
	d.position = hinge + Vector3(0, height / 2, 0)
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(width - 0.04, height - 0.04, 0.12)
	shape.shape = bs
	shape.position = Vector3(width / 2, 0, 0)
	d.add_child(shape)

	var parts: Array = [[Vector3(width - 0.04, height - 0.04, 0.12), Vector3(width / 2, 0, 0), _dark_wood]]
	for y in [-0.3 * height, 0.3 * height]:                       # iron straps
		parts.append([Vector3(width - 0.1, 0.1, 0.15), Vector3(width / 2, y, 0), _iron])
	parts.append([Vector3(0.05, 0.18, 0.2), Vector3(width - 0.15, 0, 0), _iron])   # handle
	for p in parts:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = p[0]
		mi.mesh = box
		mi.material_override = p[2]
		mi.layers = 1 | 2                  # lit from both sides of the doorway
		mi.position = p[1]
		d.add_child(mi)
	parent.add_child(d)

	var catch_body := DoorCatch.new()
	catch_body.door = d
	catch_body.collision_layer = 2          # interaction ray only; the player walks straight through
	catch_body.collision_mask = 0
	var cshape := CollisionShape3D.new()
	var cbox := BoxShape3D.new()
	cbox.size = Vector3(width - 0.1, height - 0.1, 0.4)
	cshape.shape = cbox
	catch_body.add_child(cshape)
	catch_body.position = hinge + Vector3(width / 2, height / 2, 0)
	parent.add_child(catch_body)
	return d
