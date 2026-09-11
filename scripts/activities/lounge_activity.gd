class_name LoungeActivity
extends Node3D

signal prop_registered(prop: MeetupGrabbable)
signal die_result(message: String)

var props_by_id: Dictionary = {}


func _ready() -> void:
	for index in 2:
		var ball := MeetupGrabbable.new()
		ball.name = "Ball%d" % index
		ball.prop_id = StringName("ball_%d" % index)
		ball.shape_kind = "Ball"
		ball.prop_size = Vector3.ONE * 0.62
		ball.prop_color = Color("ef7857") if index == 0 else Color("70b7dd")
		ball.position = Vector3(5.5 + index * 0.8, 1.0, -5.0)
		_register_prop(ball)
	for index in 8:
		var block := MeetupGrabbable.new()
		block.name = "Block%d" % index
		block.prop_id = StringName("block_%d" % index)
		block.prop_size = Vector3(0.55, 0.55, 0.55)
		block.prop_color = [Color("ffd166"), Color("58c7b4"), Color("ef6b75")][index % 3]
		block.position = Vector3(4.8 + float(index % 4) * 0.65, 0.7 + float(index / 4) * 0.6, 1.5)
		_register_prop(block)
	for index in 2:
		var die := MeetupDie.new()
		die.name = "Die%d" % index
		die.prop_id = StringName("die_%d" % index)
		die.position = Vector3(-1.0 + index * 0.8, 1.2, -2.0)
		die.result_settled.connect(_on_die_settled)
		_register_prop(die)


func apply_prop_state(prop_id: StringName, value_transform: Transform3D, linear_velocity: Vector3, angular_velocity: Vector3) -> void:
	var prop := props_by_id.get(prop_id) as MeetupGrabbable
	if prop != null:
		prop.apply_remote_state(value_transform, linear_velocity, angular_velocity)


func _register_prop(prop: MeetupGrabbable) -> void:
	add_child(prop)
	props_by_id[prop.prop_id] = prop
	prop_registered.emit(prop)


func _on_die_settled(_prop_id: StringName, result: int) -> void:
	die_result.emit("The die settled on %d." % result)
