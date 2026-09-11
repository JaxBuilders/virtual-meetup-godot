class_name Clubhouse
extends Node3D

const LOUNGE_ACTIVITY_SCENE := preload("res://scenes/activities/lounge_activity.tscn")

signal prop_registered(prop: MeetupGrabbable)
signal die_result(message: String)

var props_by_id: Dictionary = {}
var lounge_activity: LoungeActivity


func _ready() -> void:
	_build_environment()
	_build_clubhouse()
	_build_activity()


func apply_prop_state(prop_id: StringName, value_transform: Transform3D, linear_velocity: Vector3, angular_velocity: Vector3) -> void:
	if lounge_activity != null:
		lounge_activity.apply_prop_state(prop_id, value_transform, linear_velocity, angular_velocity)


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("8fc9df")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c8e4ef")
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -34.0, 0.0)
	sun.light_color = Color("fff0ce")
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)


func _build_clubhouse() -> void:
	var timber := Color("8f5f3d")
	var plaster := Color("ead9b7")
	var slate := Color("36536b")
	var stone := Color("7a8491")
	_static_box("Ground", Vector3(36.0, 0.5, 34.0), Vector3(0.0, -0.25, 2.0), Color("6f9b62"))
	_static_box("ClubhouseFloor", Vector3(20.0, 0.35, 16.0), Vector3(0.0, 0.18, 0.0), Color("b98958"))
	_static_box("BackWall", Vector3(20.0, 4.7, 0.35), Vector3(0.0, 2.5, -8.0), plaster)
	_static_box("LeftWall", Vector3(0.35, 4.7, 16.0), Vector3(-10.0, 2.5, 0.0), plaster)
	_static_box("RightWall", Vector3(0.35, 4.7, 16.0), Vector3(10.0, 2.5, 0.0), plaster)
	_static_box("FrontLeft", Vector3(7.0, 4.7, 0.35), Vector3(-6.5, 2.5, 8.0), plaster)
	_static_box("FrontRight", Vector3(7.0, 4.7, 0.35), Vector3(6.5, 2.5, 8.0), plaster)
	_static_box("Roof", Vector3(21.0, 0.35, 17.0), Vector3(0.0, 5.05, 0.0), slate)
	for x in [-9.5, 9.5]:
		for z in [-7.5, 7.5]:
			_static_box("Timber", Vector3(0.35, 4.8, 0.35), Vector3(x, 2.5, z), timber)
	_static_box("Patio", Vector3(18.0, 0.28, 8.0), Vector3(0.0, 0.14, 12.0), stone)
	_static_box("PatioRoof", Vector3(18.5, 0.25, 6.5), Vector3(0.0, 3.7, 11.3), slate.darkened(0.1))
	for x in [-8.5, 8.5]:
		_static_box("PatioPost", Vector3(0.3, 3.6, 0.3), Vector3(x, 1.9, 13.8), timber)
	for index in 4:
		var seat := MeetupSeat.new()
		seat.name = "Seat%d" % index
		seat.position = Vector3(-4.5 + float(index % 2) * 9.0, 0.35, -3.0 + float(index / 2) * 8.5)
		seat.rotation.y = PI if index >= 2 else 0.0
		add_child(seat)
	_static_box("CoffeeTable", Vector3(3.0, 0.18, 1.6), Vector3(0.0, 0.75, -2.0), timber)
	_static_box("TableLeg", Vector3(0.35, 0.75, 0.35), Vector3(0.0, 0.38, -2.0), timber.darkened(0.25))


func _build_activity() -> void:
	lounge_activity = LOUNGE_ACTIVITY_SCENE.instantiate() as LoungeActivity
	lounge_activity.prop_registered.connect(_register_prop)
	lounge_activity.die_result.connect(func(message: String) -> void: die_result.emit(message))
	add_child(lounge_activity)


func _register_prop(prop: MeetupGrabbable) -> void:
	props_by_id[prop.prop_id] = prop
	prop_registered.emit(prop)


func _static_box(node_name: String, size: Vector3, at: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = at
	add_child(body)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	return body
