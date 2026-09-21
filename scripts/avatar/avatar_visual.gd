class_name AvatarVisual
extends Node3D

const AUTHORED_AVATAR_PATH := "res://assets/avatars/makehuman_wardrobe_proof.glb"
const AUTHORED_ANIMATIONS_PATH := "res://assets/animations/quaternius_ual_standard/UAL1_Standard.glb"
const EMOTE_ANIMATIONS := {
	&"wave": &"Interact",
	&"point": &"Interact",
	&"clap": &"Interact",
	&"sit": &"Sitting_Idle",
	&"dance": &"Dance",
}
const LOOPING_EMOTES := [&"sit", &"dance"]

const SKIN_COLORS := {
	&"skin_amber": Color("c98a5b"),
	&"skin_umber": Color("8b573c"),
	&"skin_rose": Color("e3a184"),
	&"skin_sand": Color("d7b18a"),
	&"skin_brown": Color("70432f"),
	&"skin_deep": Color("432a24"),
}
const OUTFIT_COLORS := {
	&"outfit_teal": Color("3cb6a6"),
	&"outfit_orange": Color("e47d3a"),
	&"outfit_violet": Color("7c68d7"),
	&"outfit_charcoal": Color("454954"),
	&"outfit_cream": Color("e7d9b9"),
}

var descriptor := AvatarDescriptor.new()
var _body_root: Node3D
var _animation_player: AnimationPlayer
var _current_animation: StringName
var _active_emote: StringName
var _holding: bool = false
var _throw_time: float = 0.0


func _ready() -> void:
	build_visual()


func apply_descriptor(value: AvatarDescriptor) -> void:
	var previous := descriptor.to_dictionary()
	descriptor = value.duplicate_descriptor()
	descriptor.sanitize()
	if _animation_player != null:
		if previous != descriptor.to_dictionary():
			_apply_authored_style()
		return
	build_visual()


func build_visual() -> void:
	if _body_root != null:
		remove_child(_body_root)
		_body_root.queue_free()
	_body_root = null
	_animation_player = null
	_current_animation = &""
	if _build_authored_visual():
		return
	push_error("Authored avatar could not load. Reimport the bundled avatar and animation assets.")


func _build_authored_visual() -> bool:
	var avatar_scene := load(AUTHORED_AVATAR_PATH) as PackedScene
	var animation_scene := load(AUTHORED_ANIMATIONS_PATH) as PackedScene
	if avatar_scene == null or animation_scene == null:
		return false
	var avatar := avatar_scene.instantiate() as Node3D
	if avatar == null:
		return false
	_body_root = avatar
	_body_root.name = "AuthoredBody"
	# MPFB's exported visual faces +Z while the player controller and cameras use
	# -Z as forward. Rotate the presentation only; controller/network yaw remains
	# in the project's gameplay coordinate convention.
	_body_root.rotation.y = PI
	var body_scale := 1.05 if descriptor.body_id == &"body_tall" else 0.98
	_body_root.scale = Vector3.ONE * body_scale
	add_child(_body_root)
	var source := animation_scene.instantiate()
	var source_player := _find_animation_player(source)
	if source_player == null or not source_player.has_animation_library(&""):
		source.free()
		remove_child(_body_root)
		_body_root.free()
		_body_root = null
		return false
	var library := source_player.get_animation_library(&"")
	source.free()
	_animation_player = AnimationPlayer.new()
	_animation_player.name = "AvatarAnimationPlayer"
	_body_root.add_child(_animation_player)
	_animation_player.add_animation_library(&"", library)
	_animation_player.animation_finished.connect(_on_animation_finished)
	_apply_authored_style()
	_play_authored_animation(&"Idle", 1.0, 0.0)
	return true


func _apply_authored_style() -> void:
	_body_root.scale = Vector3.ONE * (1.05 if descriptor.body_id == &"body_tall" else 0.98)
	for child: Node in _body_root.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		var mesh_name := str(mesh.name).to_lower()
		if mesh_name.contains("short01"):
			mesh.visible = descriptor.hair_id != &"hair_bald"
		if mesh_name.contains("casualsuit"):
			_tint_mesh(mesh, OUTFIT_COLORS[descriptor.outfit_id])
		elif mesh_name == "body":
			_tint_mesh(mesh, SKIN_COLORS[descriptor.skin_id])


func _tint_mesh(mesh: MeshInstance3D, color: Color) -> void:
	for surface in mesh.mesh.get_surface_count():
		var source := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
		if source == null:
			continue
		var material := source.duplicate() as StandardMaterial3D
		material.albedo_color = color
		mesh.set_surface_override_material(surface, material)


func animate_motion(speed: float, grounded: bool, delta: float) -> void:
	_throw_time = maxf(0.0, _throw_time - delta)
	if _animation_player != null:
		_animate_authored(speed, grounded)


func play_emote(emote_id: StringName, active := true) -> void:
	_active_emote = emote_id if active else &""
	if not active and _animation_player != null:
		_play_authored_animation(&"Idle")


func set_holding(value: bool) -> void:
	_holding = value


func play_throw() -> void:
	_throw_time = 0.32


func uses_authored_visual() -> bool:
	return _animation_player != null


func current_animation() -> StringName:
	return _current_animation


func _animate_authored(speed: float, grounded: bool) -> void:
	if _active_emote != &"":
		var emote_animation: StringName = EMOTE_ANIMATIONS.get(_active_emote, &"Idle")
		_play_authored_animation(emote_animation)
		return
	if _throw_time > 0.0:
		_play_authored_animation(&"Push")
		return
	if _holding:
		_play_authored_animation(&"Pistol_Idle")
		return
	if not grounded:
		_play_authored_animation(&"Jump")
		return
	if speed < 0.15:
		_play_authored_animation(&"Idle")
	elif speed < 5.35:
		_play_authored_animation(&"Walk", clampf(speed / 4.3, 0.65, 1.35))
	else:
		_play_authored_animation(&"Jog_Fwd", clampf(speed / 6.4, 0.8, 1.3))


func _play_authored_animation(animation_name: StringName, speed_scale := 1.0, blend := 0.18) -> void:
	if _animation_player == null or not _animation_player.has_animation(animation_name):
		return
	if _current_animation == animation_name and _animation_player.is_playing():
		_animation_player.speed_scale = speed_scale
		return
	_current_animation = animation_name
	_animation_player.play(animation_name, blend, speed_scale)


func _on_animation_finished(animation_name: StringName) -> void:
	if _active_emote != &"" and not LOOPING_EMOTES.has(_active_emote):
		_active_emote = &""
	if animation_name == _current_animation and not LOOPING_EMOTES.has(_active_emote):
		_play_authored_animation(&"Idle")


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child: Node in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null
