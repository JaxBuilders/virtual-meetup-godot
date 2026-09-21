class_name AvatarGallery
extends Node3D

const MAKEHUMAN_BASELINE := preload("res://assets/avatars/makehuman_baseline.glb")
const MAKEHUMAN_WARDROBE_PROOF := preload("res://assets/avatars/makehuman_wardrobe_proof.glb")
const QUATERNIUS_ANIMATIONS := preload("res://assets/animations/quaternius_ual_standard/UAL1_Standard.glb")


func _ready() -> void:
	_build_environment()
	_build_floor()
	_build_displays()
	_build_makehuman_display()


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("26354c")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d8edf1")
	environment.ambient_light_energy = 0.7
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	key.light_color = Color("fff1d4")
	key.light_energy = 1.1
	key.shadow_enabled = true
	add_child(key)


func _build_floor() -> void:
	var body := StaticBody3D.new()
	add_child(body)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(28.0, 0.3, 32.0)
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("66758b")
	material.roughness = 0.88
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	collider.shape = shape
	body.add_child(collider)


func _build_displays() -> void:
	var index := 0
	for body_id in AvatarDescriptor.BODY_IDS:
		for outfit_id in AvatarDescriptor.OUTFIT_IDS:
			var descriptor := AvatarDescriptor.new()
			descriptor.body_id = body_id
			descriptor.skin_id = AvatarDescriptor.SKIN_IDS[index % AvatarDescriptor.SKIN_IDS.size()]
			descriptor.hair_id = AvatarDescriptor.HAIR_IDS[index % AvatarDescriptor.HAIR_IDS.size()]
			descriptor.outfit_id = outfit_id
			descriptor.accessory_id = AvatarDescriptor.ACCESSORY_IDS[index % AvatarDescriptor.ACCESSORY_IDS.size()]
			var display := AvatarVisual.new()
			display.position = Vector3(-7.5 + float(index % 3) * 7.5, 0.15, -3.5 + float(index / 3) * 7.0)
			add_child(display)
			display.apply_descriptor(descriptor)
			var label := Label3D.new()
			label.text = "%s / %s" % [str(body_id).trim_prefix("body_").capitalize(), str(outfit_id).trim_prefix("outfit_").capitalize()]
			label.position = display.position + Vector3(0.0, 2.5, 0.0)
			label.font_size = 32
			label.outline_size = 6
			add_child(label)
			index += 1


func _build_makehuman_display() -> void:
	var source := QUATERNIUS_ANIMATIONS.instantiate()
	var source_player := _find_animation_player(source)
	var library := source_player.get_animation_library(&"")
	source.free()
	_build_retarget_row(MAKEHUMAN_BASELINE, library, "MPFB Baseline", 9.0)
	_build_retarget_row(MAKEHUMAN_WARDROBE_PROOF, library, "CC0 Wardrobe", 13.0)


func _build_retarget_row(scene: PackedScene, library: AnimationLibrary, title: String, z_position: float) -> void:
	var demonstrations := {
		"Idle": Vector3(-4.0, 0.15, z_position),
		"Walk": Vector3(0.0, 0.15, z_position),
		"Dance": Vector3(4.0, 0.15, z_position),
	}
	for animation_name: StringName in demonstrations:
		var display := scene.instantiate() as Node3D
		display.name = "%s%s" % [title.replace(" ", ""), animation_name]
		display.position = demonstrations[animation_name]
		add_child(display)
		var player := AnimationPlayer.new()
		display.add_child(player)
		player.add_animation_library(&"", library)
		player.play(animation_name)
		var label := Label3D.new()
		label.text = "%s / %s\nRetargeted" % [title, animation_name]
		label.position = display.position + Vector3(0.0, 2.15, 0.0)
		label.font_size = 30
		label.outline_size = 6
		add_child(label)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child: Node in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null
