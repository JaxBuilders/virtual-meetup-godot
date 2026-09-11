class_name MeetupDie
extends MeetupGrabbable

signal result_settled(prop_id: StringName, result: int)

var _was_moving: bool = false
var _reported_sleep: bool = false


func _ready() -> void:
	shape_kind = "Box"
	prop_size = Vector3.ONE * 0.42
	prop_color = Color("f3e7cf")
	prompt = "E  Pick up die"
	super._ready()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	var moving := linear_velocity.length_squared() + angular_velocity.length_squared() > 0.05
	if moving:
		_was_moving = true
		_reported_sleep = false
	elif _was_moving and not _reported_sleep:
		_reported_sleep = true
		result_settled.emit(prop_id, get_up_face())


func get_up_face() -> int:
	var directions := [
		[global_basis.y, 1],
		[-global_basis.y, 6],
		[global_basis.x, 2],
		[-global_basis.x, 5],
		[global_basis.z, 3],
		[-global_basis.z, 4],
	]
	var best_face := 1
	var best_dot := -1.0
	for entry in directions:
		var dot_value := (entry[0] as Vector3).dot(Vector3.UP)
		if dot_value > best_dot:
			best_dot = dot_value
			best_face = int(entry[1])
	return best_face
