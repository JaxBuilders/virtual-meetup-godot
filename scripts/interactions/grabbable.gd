class_name MeetupGrabbable
extends RigidBody3D

signal state_changed(prop_id: StringName, transform: Transform3D, linear_velocity: Vector3, angular_velocity: Vector3)

@export var prop_id: StringName
@export var prompt: String = "E  Pick up"
@export var prop_color: Color = Color("6fc5d1")
@export var prop_size: Vector3 = Vector3(0.45, 0.45, 0.45)
@export_enum("Box", "Ball") var shape_kind: String = "Box"

var held_by: MeetupPlayerController
var _original_parent: Node
var _publish_cooldown: float = 0.0
var _remote_suppression: float = 0.0


func _ready() -> void:
	_original_parent = get_parent()
	collision_layer = 4
	collision_mask = 3
	mass = 1.0
	_build_visual()


func _physics_process(delta: float) -> void:
	_remote_suppression = maxf(0.0, _remote_suppression - delta)
	if held_by == null and not sleeping:
		_publish_cooldown -= delta
		if _publish_cooldown <= 0.0 and _remote_suppression <= 0.0:
			_publish_cooldown = 0.2
			state_changed.emit(prop_id, global_transform, linear_velocity, angular_velocity)


func get_interaction_prompt(_actor: Node) -> String:
	return prompt if held_by == null else "In use"


func interact(actor: Node) -> void:
	var player := actor as MeetupPlayerController
	if player != null and held_by == null:
		player.hold_object(self)


func begin_hold(anchor: Node3D) -> void:
	var ancestor: Node = anchor
	while ancestor != null and not ancestor is MeetupPlayerController:
		ancestor = ancestor.get_parent()
	held_by = ancestor as MeetupPlayerController
	if held_by == null:
		return
	freeze = true
	reparent(anchor, false)
	position = Vector3.ZERO
	rotation = Vector3.ZERO


func end_hold(impulse: Vector3) -> void:
	var world_transform := global_transform
	reparent(_original_parent, false)
	global_transform = world_transform
	held_by = null
	freeze = false
	linear_velocity = impulse.limit_length(12.0)
	angular_velocity = Vector3(2.5, 4.0, 1.5) if impulse.length() > 2.0 else Vector3.ZERO
	state_changed.emit(prop_id, global_transform, linear_velocity, angular_velocity)


func apply_remote_state(value_transform: Transform3D, value_linear: Vector3, value_angular: Vector3) -> void:
	if held_by != null:
		return
	global_transform = value_transform
	linear_velocity = value_linear.limit_length(15.0)
	angular_velocity = value_angular.limit_length(20.0)
	_remote_suppression = 0.3


func _build_visual() -> void:
	var mesh_instance := MeshInstance3D.new()
	var collision := CollisionShape3D.new()
	if shape_kind == "Ball":
		var mesh := SphereMesh.new()
		mesh.radius = prop_size.x * 0.5
		mesh.height = prop_size.x
		mesh_instance.mesh = mesh
		var sphere := SphereShape3D.new()
		sphere.radius = prop_size.x * 0.5
		collision.shape = sphere
	else:
		var mesh := BoxMesh.new()
		mesh.size = prop_size
		mesh_instance.mesh = mesh
		var box := BoxShape3D.new()
		box.size = prop_size
		collision.shape = box
	var material := StandardMaterial3D.new()
	material.albedo_color = prop_color
	material.roughness = 0.72
	mesh_instance.material_override = material
	add_child(mesh_instance)
	add_child(collision)
