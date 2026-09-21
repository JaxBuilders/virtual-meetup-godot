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
var _left_arm: Node3D
var _right_arm: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _animation_player: AnimationPlayer
var _current_animation: StringName
var _animation_time: float = 0.0
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
	_left_arm = null
	_right_arm = null
	_left_leg = null
	_right_leg = null
	if _build_authored_visual():
		return
	_build_primitive_fallback()


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
	var skeleton := _body_root.find_child("GeneralSkeleton", true, false) as Skeleton3D
	if skeleton == null:
		return
	for child: Node in skeleton.get_children():
		if child is BoneAttachment3D and child.name in [&"CustomizationHead", &"CustomizationChest"]:
			skeleton.remove_child(child)
			child.queue_free()
	var head_index := skeleton.find_bone(&"Head")
	if head_index < 0:
		return
	var head_rest := skeleton.get_bone_global_rest(head_index)
	var socket := BoneAttachment3D.new()
	socket.name = "CustomizationHead"
	socket.bone_name = &"Head"
	skeleton.add_child(socket)
	# Place accessories in model-space meters, then express their transform in
	# the imported head bone's local rest frame so they follow every animation.
	var accessories := Node3D.new()
	accessories.transform = head_rest.affine_inverse() * Transform3D(Basis.IDENTITY, head_rest.origin)
	socket.add_child(accessories)
	if descriptor.hair_id == &"hair_cap":
		_add_sphere(accessories, "Cap", Vector3(0, 0.17, -0.015), 0.11, Color("263b61"), Vector3(1.0, 0.5, 1.1))
		_add_box(accessories, "CapBrim", Vector3(0, 0.14, 0.09), Vector3(0.19, 0.015, 0.16), Color("263b61"))
	elif descriptor.hair_id == &"hair_bun":
		_add_sphere(accessories, "Bun", Vector3(0, 0.16, -0.11), 0.065, Color("342821"))
	if descriptor.accessory_id == &"glasses":
		_add_box(accessories, "GlassesBridge", Vector3(0, 0.085, 0.105), Vector3(0.025, 0.012, 0.014), Color("182132"))
		for side: float in [-1.0, 1.0]:
			_add_box(accessories, "Lens", Vector3(side * 0.041, 0.085, 0.10), Vector3(0.064, 0.042, 0.012), Color("263b61"))
	elif descriptor.accessory_id == &"badge":
		var chest_index := skeleton.find_bone(&"Chest")
		if chest_index >= 0:
			var chest_rest := skeleton.get_bone_global_rest(chest_index)
			var chest_socket := BoneAttachment3D.new()
			chest_socket.name = "CustomizationChest"
			chest_socket.bone_name = &"Chest"
			skeleton.add_child(chest_socket)
			var badge := _add_box(chest_socket, "Badge", Vector3.ZERO, Vector3(0.045, 0.055, 0.01), Color("ffd166"))
			badge.transform = chest_rest.affine_inverse() * Transform3D(Basis.IDENTITY, chest_rest.origin + Vector3(0.08, 0.04, 0.14))


func _tint_mesh(mesh: MeshInstance3D, color: Color) -> void:
	for surface in mesh.mesh.get_surface_count():
		var source := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
		if source == null:
			continue
		var material := source.duplicate() as StandardMaterial3D
		material.albedo_color = color
		mesh.set_surface_override_material(surface, material)


func _build_primitive_fallback() -> void:
	_body_root = Node3D.new()
	_body_root.name = "PrimitiveFallbackBody"
	add_child(_body_root)
	var tall := descriptor.body_id == &"body_tall"
	var body_scale := 1.08 if tall else 0.96
	_body_root.scale = Vector3(body_scale, 1.08 if tall else 0.96, body_scale)
	var skin: Color = SKIN_COLORS.get(descriptor.skin_id, SKIN_COLORS[&"skin_amber"])
	var outfit: Color = OUTFIT_COLORS.get(descriptor.outfit_id, OUTFIT_COLORS[&"outfit_teal"])
	_add_capsule(_body_root, "Torso", Vector3(0.0, 1.15, 0.0), 0.28, 0.62, outfit)
	_add_sphere(_body_root, "Head", Vector3(0.0, 1.72, 0.0), 0.25, skin)
	_left_arm = _limb("LeftArm", Vector3(-0.35, 1.25, 0.0), skin, outfit)
	_right_arm = _limb("RightArm", Vector3(0.35, 1.25, 0.0), skin, outfit)
	_left_leg = _leg("LeftLeg", Vector3(-0.15, 0.58, 0.0), outfit)
	_right_leg = _leg("RightLeg", Vector3(0.15, 0.58, 0.0), outfit)
	_build_hair(skin)
	_build_accessory()


func animate_motion(speed: float, grounded: bool, delta: float) -> void:
	_animation_time += delta * clampf(speed * 2.2, 2.0, 12.0)
	_throw_time = maxf(0.0, _throw_time - delta)
	if _animation_player != null:
		_animate_authored(speed, grounded)
		return
	var swing := sin(_animation_time) * clampf(speed / 5.0, 0.0, 0.75) if grounded else 0.2
	if _active_emote == &"sit":
		_body_root.position.y = lerpf(_body_root.position.y, -0.35, delta * 10.0)
		_left_arm.rotation = Vector3(-0.3, 0.0, -0.08)
		_right_arm.rotation = Vector3(-0.3, 0.0, 0.08)
		_left_leg.rotation.x = -1.25
		_right_leg.rotation.x = -1.25
		return
	_body_root.position.y = lerpf(_body_root.position.y, 0.0, delta * 10.0)
	if _active_emote == &"wave":
		_right_arm.rotation = Vector3(0.0, 0.0, -1.9 + sin(_animation_time * 2.0) * 0.35)
	elif _active_emote == &"point":
		_right_arm.rotation = Vector3(-1.5, 0.0, -0.15)
	elif _active_emote == &"clap":
		_left_arm.rotation = Vector3(-1.1, 0.0, -0.8 + abs(sin(_animation_time * 2.0)) * 0.45)
		_right_arm.rotation = Vector3(-1.1, 0.0, 0.8 - abs(sin(_animation_time * 2.0)) * 0.45)
	elif _active_emote == &"dance":
		_body_root.rotation.y = sin(_animation_time) * 0.25
		_left_arm.rotation.z = -0.7 + sin(_animation_time * 1.7) * 0.5
		_right_arm.rotation.z = 0.7 - sin(_animation_time * 1.7) * 0.5
	elif _throw_time > 0.0:
		_left_arm.rotation = Vector3(0.1, 0.0, -0.08)
		_right_arm.rotation = Vector3(-2.1 + _throw_time * 2.0, 0.0, 0.08)
	elif _holding:
		_left_arm.rotation = Vector3(0.05, 0.0, -0.08)
		_right_arm.rotation = Vector3(-1.15, 0.0, 0.18)
	else:
		_body_root.rotation.y = lerpf(_body_root.rotation.y, 0.0, delta * 8.0)
		_left_arm.rotation = Vector3(swing, 0.0, -0.08)
		_right_arm.rotation = Vector3(-swing, 0.0, 0.08)
	_left_leg.rotation.x = -swing
	_right_leg.rotation.x = swing


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


func _limb(node_name: String, at: Vector3, skin: Color, outfit: Color) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	root.position = at
	_body_root.add_child(root)
	_add_capsule(root, "Sleeve", Vector3(0.0, -0.08, 0.0), 0.105, 0.34, outfit)
	_add_capsule(root, "Forearm", Vector3(0.0, -0.38, 0.0), 0.085, 0.30, skin)
	return root


func _leg(node_name: String, at: Vector3, color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	root.position = at
	_body_root.add_child(root)
	_add_capsule(root, "Leg", Vector3(0.0, -0.18, 0.0), 0.12, 0.54, color.darkened(0.28))
	_add_capsule(root, "Shoe", Vector3(0.0, -0.50, -0.06), 0.13, 0.18, Color("30394d"), Vector3(1.0, 1.0, 1.45))
	return root


func _build_hair(_skin: Color) -> void:
	var hair_color := Color("342821")
	match descriptor.hair_id:
		&"hair_crop":
			_add_sphere(_body_root, "Hair", Vector3(0.0, 1.84, 0.0), 0.255, hair_color, Vector3(1.0, 0.55, 1.0))
		&"hair_cap":
			_add_sphere(_body_root, "Hair", Vector3(0.0, 1.87, -0.01), 0.27, Color("263b61"), Vector3(1.04, 0.55, 1.04))
		&"hair_bun":
			_add_sphere(_body_root, "Hair", Vector3(0.0, 1.84, 0.0), 0.255, hair_color, Vector3(1.0, 0.6, 1.0))
			_add_sphere(_body_root, "Bun", Vector3(0.0, 2.08, 0.04), 0.13, hair_color)


func _build_accessory() -> void:
	if descriptor.accessory_id == &"glasses":
		_add_box(_body_root, "Glasses", Vector3(0.0, 1.73, -0.235), Vector3(0.34, 0.06, 0.035), Color("182132"))
	elif descriptor.accessory_id == &"badge":
		_add_box(_body_root, "Badge", Vector3(0.16, 1.28, -0.27), Vector3(0.10, 0.10, 0.02), Color("ffd166"))


func _add_capsule(parent: Node3D, node_name: String, at: Vector3, radius: float, height: float, color: Color, mesh_scale := Vector3.ONE) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(height, radius * 2.0)
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = at
	instance.scale = mesh_scale
	instance.material_override = _material(color)
	parent.add_child(instance)
	return instance


func _add_sphere(parent: Node3D, node_name: String, at: Vector3, radius: float, color: Color, mesh_scale := Vector3.ONE) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = at
	instance.scale = mesh_scale
	instance.material_override = _material(color)
	parent.add_child(instance)
	return instance


func _add_box(parent: Node3D, node_name: String, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = at
	instance.material_override = _material(color)
	parent.add_child(instance)
	return instance


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	return material
