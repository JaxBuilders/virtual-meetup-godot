class_name MeetupSeat
extends Interactable

var occupant: MeetupPlayerController
var seat_anchor: Marker3D


func _ready() -> void:
	interaction_prompt = "E  Sit"
	_build_visual()


func _process(_delta: float) -> void:
	if occupant != null and (not is_instance_valid(occupant) or occupant.seated_at != seat_anchor):
		occupant = null


func get_interaction_prompt(actor: Node) -> String:
	if occupant != null and occupant != actor:
		return "Seat occupied"
	return "E  Stand" if occupant == actor else "E  Sit"


func interact(actor: Node) -> void:
	var player := actor as MeetupPlayerController
	if player == null:
		return
	if occupant == player:
		player.leave_seat()
		occupant = null
	elif occupant == null and player.sit_on(seat_anchor):
		occupant = player


func _build_visual() -> void:
	var body := StaticBody3D.new()
	body.name = "SeatCollision"
	add_child(body)
	_add_box(body, Vector3(1.15, 0.16, 0.95), Vector3(0.0, 0.46, 0.0), Color("a96f45"))
	_add_box(body, Vector3(1.15, 0.9, 0.14), Vector3(0.0, 0.9, 0.4), Color("825437"))
	_add_box(body, Vector3(0.12, 0.48, 0.12), Vector3(-0.45, 0.22, -0.3), Color("5a3b2a"))
	_add_box(body, Vector3(0.12, 0.48, 0.12), Vector3(0.45, 0.22, -0.3), Color("5a3b2a"))
	seat_anchor = Marker3D.new()
	seat_anchor.name = "SeatAnchor"
	seat_anchor.position = Vector3(0.0, 0.5, -0.05)
	add_child(seat_anchor)


func _add_box(body: StaticBody3D, size: Vector3, at: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	body.add_child(shape)
