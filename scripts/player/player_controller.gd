class_name MeetupPlayerController
extends CharacterBody3D

signal prompt_changed(prompt: String)
signal chat_requested
signal emotes_requested
signal menu_requested
signal cancel_requested
signal emote_requested(emote_id: StringName, active: bool)
signal pose_ready(position: Vector3, yaw: float, velocity: Vector3)

const WALK_SPEED := 4.3
const SPRINT_SPEED := 6.4
const GROUND_ACCELERATION := 18.0
const AIR_ACCELERATION := 6.0
const JUMP_VELOCITY := 7.0
const GRAVITY := 22.0
const INTERACTION_DISTANCE := 3.2
const THIRD_PERSON_ZOOM_STEP := 0.65
const THIRD_PERSON_MIN_DISTANCE := 1.2
const THIRD_PERSON_MAX_DISTANCE := 8.0
const CHARACTER_TURN_SPEED := 12.0

var input_source: PlayerInputSource
var avatar_visual: AvatarVisual
var camera_pivot: Node3D
var spring_arm: SpringArm3D
var camera: Camera3D
var interaction_ray: RayCast3D
var hold_anchor: Marker3D
var held_object: Node3D
var is_first_person: bool = false
var input_suppressed: bool = false
var seated_at: Node3D
var local_controlled: bool = true
var third_person_distance: float = 4.2
var camera_yaw: float = 0.0
var _pose_cooldown: float = 0.0
var _current_prompt: String = ""


func _ready() -> void:
	_build_nodes()
	camera_yaw = rotation.y
	floor_snap_length = 0.35
	floor_max_angle = deg_to_rad(52.0)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	SettingsStore.settings_changed.connect(_apply_settings)


func _physics_process(delta: float) -> void:
	if not local_controlled:
		avatar_visual.animate_motion(Vector2(velocity.x, velocity.z).length(), is_on_floor(), delta)
		return
	input_source.world_input_enabled = not input_suppressed
	input_source.mouse_look_enabled = not input_suppressed
	var command := input_source.sample_command()
	_process_global_shortcuts(command)
	if input_suppressed:
		# Menus suppress commands, not simulation or animation state updates.
		# Replace the sampled command after shortcuts, which may open a menu.
		command = PlayerCommand.new()
	_process_look(command.look)
	if command.view_pressed:
		set_first_person(not is_first_person)
	adjust_third_person_zoom(command.camera_zoom)
	if seated_at != null:
		velocity = Vector3.ZERO
		global_position = seated_at.global_position
		if command.jump_pressed or command.interact_pressed:
			leave_seat()
	else:
		_simulate_movement(command, delta)
		_process_interaction(command)
	_update_prompt()
	avatar_visual.animate_motion(Vector2(velocity.x, velocity.z).length(), is_on_floor(), delta)
	_pose_cooldown -= delta
	if _pose_cooldown <= 0.0:
		_pose_cooldown = 1.0 / 15.0
		pose_ready.emit(global_position, rotation.y, velocity)


func set_profile_avatar(descriptor: AvatarDescriptor) -> void:
	avatar_visual.apply_descriptor(descriptor)


func set_local_controlled(value: bool) -> void:
	local_controlled = value
	camera.current = value
	input_source.set_process_unhandled_input(value)
	if not value:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func set_input_suppressed(value: bool) -> void:
	input_suppressed = value
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED


func set_first_person(value: bool) -> void:
	if value and not is_first_person:
		rotation.y = camera_yaw
		camera_pivot.rotation.y = 0.0
	is_first_person = value
	spring_arm.spring_length = 0.05 if value else third_person_distance
	avatar_visual.visible = not value
	_update_third_person_camera_offset()


func adjust_third_person_zoom(wheel_steps: float) -> void:
	if is_first_person or is_zero_approx(wheel_steps):
		return
	third_person_distance = clampf(
		third_person_distance + wheel_steps * THIRD_PERSON_ZOOM_STEP,
		THIRD_PERSON_MIN_DISTANCE,
		THIRD_PERSON_MAX_DISTANCE
	)
	spring_arm.spring_length = third_person_distance


func sit_on(anchor: Node3D) -> bool:
	if seated_at != null or held_object != null:
		return false
	seated_at = anchor
	global_position = anchor.global_position
	rotation.y = anchor.global_rotation.y
	if is_first_person:
		camera_yaw = rotation.y
	else:
		_update_third_person_camera_offset()
	avatar_visual.play_emote(&"sit", true)
	return true


func leave_seat() -> void:
	if seated_at == null:
		return
	global_position += seated_at.global_basis.z * 0.85
	seated_at = null
	avatar_visual.play_emote(&"sit", false)


func hold_object(object: Node3D) -> bool:
	if held_object != null or seated_at != null or not object.has_method("begin_hold"):
		return false
	held_object = object
	object.call("begin_hold", hold_anchor)
	avatar_visual.set_holding(true)
	return true


func drop_held(throw_object := false) -> void:
	if held_object == null:
		return
	var object := held_object
	held_object = null
	avatar_visual.set_holding(false)
	if throw_object:
		avatar_visual.play_throw()
	var impulse := -camera.global_basis.z * (9.0 if throw_object else 1.5)
	object.call("end_hold", impulse)


func play_emote(emote_id: StringName, active := true) -> void:
	avatar_visual.play_emote(emote_id, active)
	emote_requested.emit(emote_id, active)


func _build_nodes() -> void:
	input_source = PlayerInputSource.new()
	input_source.name = "InputSource"
	add_child(input_source)
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	collider.shape = capsule
	collider.position.y = 0.9
	add_child(collider)
	avatar_visual = AvatarVisual.new()
	avatar_visual.name = "AvatarVisual"
	add_child(avatar_visual)
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	camera_pivot.position.y = 1.62
	add_child(camera_pivot)
	spring_arm = SpringArm3D.new()
	spring_arm.name = "SpringArm"
	spring_arm.spring_length = third_person_distance
	spring_arm.margin = 0.15
	camera_pivot.add_child(spring_arm)
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.current = true
	camera.fov = SettingsStore.field_of_view
	spring_arm.add_child(camera)
	interaction_ray = RayCast3D.new()
	interaction_ray.name = "InteractionRay"
	interaction_ray.target_position = Vector3(0.0, 0.0, -INTERACTION_DISTANCE)
	interaction_ray.collision_mask = 1 | 4
	camera.add_child(interaction_ray)
	hold_anchor = Marker3D.new()
	hold_anchor.name = "HoldAnchor"
	hold_anchor.position = Vector3(0.45, -0.35, -1.35)
	camera.add_child(hold_anchor)


func _apply_settings() -> void:
	if camera != null:
		camera.fov = SettingsStore.field_of_view


func _process_global_shortcuts(command: PlayerCommand) -> void:
	if command.chat_pressed and not input_suppressed:
		chat_requested.emit()
	if command.emotes_pressed and not input_suppressed:
		emotes_requested.emit()
	if command.menu_pressed:
		menu_requested.emit()
	if command.cancel_pressed:
		cancel_requested.emit()


func _process_look(look: Vector2) -> void:
	camera_yaw = wrapf(camera_yaw - look.x * SettingsStore.mouse_sensitivity, -PI, PI)
	if is_first_person:
		rotation.y = camera_yaw
		camera_pivot.rotation.y = 0.0
	else:
		_update_third_person_camera_offset()
	camera_pivot.rotation.x = clampf(camera_pivot.rotation.x - look.y * SettingsStore.mouse_sensitivity, deg_to_rad(-75.0), deg_to_rad(70.0))


func _simulate_movement(command: PlayerCommand, delta: float) -> void:
	var world_direction := _camera_relative_movement(command.movement)
	if not is_first_person and not world_direction.is_zero_approx():
		_orient_character_to_movement(world_direction, delta)
	var speed := SPRINT_SPEED if command.sprint_held else WALK_SPEED
	var desired := world_direction * speed
	var acceleration := GROUND_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, desired.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired.z, acceleration * delta)
	if is_on_floor():
		if command.jump_pressed:
			velocity.y = JUMP_VELOCITY
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()
	if global_position.y < -8.0:
		global_position = Vector3(0.0, 2.0, 5.0)
		velocity = Vector3.ZERO


func _camera_relative_movement(input_direction: Vector2) -> Vector3:
	var local_direction := Vector3(input_direction.x, 0.0, input_direction.y)
	return (Basis(Vector3.UP, camera_yaw) * local_direction).normalized()


func _orient_character_to_movement(world_direction: Vector3, delta: float) -> void:
	var target_yaw := atan2(-world_direction.x, -world_direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(1.0, CHARACTER_TURN_SPEED * delta))
	if is_first_person:
		camera_yaw = rotation.y
	else:
		_update_third_person_camera_offset()


func _update_third_person_camera_offset() -> void:
	if camera_pivot == null or is_first_person:
		return
	camera_pivot.rotation.y = wrapf(camera_yaw - rotation.y, -PI, PI)


func _process_interaction(command: PlayerCommand) -> void:
	if command.primary_pressed and held_object != null:
		drop_held(true)
		return
	if not command.interact_pressed:
		return
	if held_object != null:
		drop_held(false)
		return
	var target := _interaction_target()
	if target != null and target.has_method("interact"):
		target.call("interact", self)


func _update_prompt() -> void:
	var prompt := "E  Drop   •   Click  Throw" if held_object != null else ""
	if held_object == null:
		var target := _interaction_target()
		if target != null and target.has_method("get_interaction_prompt"):
			prompt = str(target.call("get_interaction_prompt", self))
	if prompt != _current_prompt:
		_current_prompt = prompt
		prompt_changed.emit(prompt)


func _interaction_target() -> Node:
	if not interaction_ray.is_colliding():
		return null
	var node := interaction_ray.get_collider() as Node
	while node != null and node != get_tree().root:
		if node.has_method("interact"):
			return node
		node = node.get_parent()
	return null
