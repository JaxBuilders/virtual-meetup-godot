class_name AvatarVisual
extends Node3D

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
}

var descriptor := AvatarDescriptor.new()
var _body_root: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _animation_time: float = 0.0
var _active_emote: StringName
var _holding: bool = false
var _throw_time: float = 0.0


func _ready() -> void:
	build_visual()


func apply_descriptor(value: AvatarDescriptor) -> void:
	descriptor = value.duplicate_descriptor()
	descriptor.sanitize()
	build_visual()


func build_visual() -> void:
	if _body_root != null:
		_body_root.queue_free()
	_body_root = Node3D.new()
	_body_root.name = "Body"
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


func set_holding(value: bool) -> void:
	_holding = value


func play_throw() -> void:
	_throw_time = 0.32


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
