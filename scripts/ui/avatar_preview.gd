class_name AvatarPreview
extends SubViewportContainer

var avatar: AvatarVisual
var _viewport: SubViewport
var _pending := AvatarDescriptor.new()


func _ready() -> void:
	custom_minimum_size = Vector2(220.0, 300.0)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	stretch = true
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(220, 300)
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(_viewport)
	var world := Node3D.new()
	_viewport.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("26354c")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.65
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -30, 0)
	world.add_child(light)
	avatar = AvatarVisual.new()
	world.add_child(avatar)
	avatar.apply_descriptor(_pending)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(0, 1.0, -3.3)
	camera.look_at(Vector3(0, 0.9, 0))
	camera.fov = 38.0
	camera.current = true


func apply_descriptor(value: AvatarDescriptor) -> void:
	_pending = value.duplicate_descriptor()
	if avatar != null:
		avatar.apply_descriptor(_pending)
