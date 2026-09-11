class_name PlayerInputSource
extends Node

var world_input_enabled: bool = true
var mouse_look_enabled: bool = true
var _look_accumulator: Vector2 = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse_look_enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look_accumulator += (event as InputEventMouseMotion).relative


func sample_command() -> PlayerCommand:
	var command := PlayerCommand.new()
	command.chat_pressed = Input.is_action_just_pressed("open_chat")
	command.emotes_pressed = Input.is_action_just_pressed("open_emotes")
	command.menu_pressed = Input.is_action_just_pressed("toggle_room_menu")
	command.cancel_pressed = Input.is_action_just_pressed("ui_cancel")
	if world_input_enabled:
		command.movement = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		command.look = _look_accumulator
		command.jump_pressed = Input.is_action_just_pressed("jump")
		command.sprint_held = Input.is_action_pressed("sprint")
		command.interact_pressed = Input.is_action_just_pressed("interact")
		command.primary_pressed = Input.is_action_just_pressed("primary_action")
		command.view_pressed = Input.is_action_just_pressed("toggle_view")
	_look_accumulator = Vector2.ZERO
	return command
