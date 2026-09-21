extends Node

const TEST_COUNT := 23

var failures: PackedStringArray = []


func _ready() -> void:
	_test_invite_codes()
	_test_avatar_fallbacks()
	_test_chat_sanitization()
	_test_profile_sanitization()
	await _test_shared_profile_controls()
	_test_resources()
	_test_project_configuration()
	_test_isolated_storage_configuration()
	_test_network_state_codec()
	_test_prop_state_rejects_stale_revisions()
	_test_prop_state_uses_shared_live_packet()
	_test_participant_rejoin_clears_departed_state()
	await _test_hud_participant_row_replacement()
	_test_settings_round_trip()
	_test_profile_round_trip()
	await get_tree().process_frame
	_test_runtime_nodes()
	await get_tree().process_frame
	await _test_offline_room_bootstrap()
	await _test_offline_chat_loop()
	await _test_offline_emote_loop()
	await _test_offline_interaction_loop()
	await _test_offline_leave_loop()
	await _test_remote_avatar_placeholder_replacement()
	await _test_remote_avatar_cleanup()
	if failures.is_empty():
		print("VIRTUAL_MEETUP_TESTS passed=%d failed=0" % TEST_COUNT)
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("VIRTUAL_MEETUP_TESTS passed=%d failed=%d" % [TEST_COUNT - failures.size(), failures.size()])
		get_tree().quit(1)


func _test_invite_codes() -> void:
	var code := InviteCode.generate(&"eu")
	var parsed := InviteCode.parse(code)
	_expect(str(parsed.get("region", "")) == "eu", "Invite code should retain its Photon region.")
	_expect(str(parsed.get("token", "")).length() == 8, "Invite code token should have eight characters.")
	_expect(InviteCode.parse("not-a-code").is_empty(), "Malformed invite code should fail closed.")


func _test_avatar_fallbacks() -> void:
	var descriptor := AvatarDescriptor.from_dictionary({"body": "unknown", "skin": "skin_deep"})
	_expect(descriptor.body_id == AvatarDescriptor.BODY_IDS[0], "Unknown body should use the default.")
	_expect(descriptor.skin_id == &"skin_deep", "Allowed skin should survive decoding.")


func _test_chat_sanitization() -> void:
	var sanitized := SessionTransport.sanitize_chat("  [b]hello[/b]\nworld  ")
	_expect(not sanitized.contains("["), "Chat should escape BBCode delimiters.")
	_expect(not sanitized.contains("\n"), "Chat should be one line.")
	_expect(SessionTransport.sanitize_chat("x".repeat(400)).length() == 280, "Chat should be bounded.")
	var transport := SessionTransport.new()
	_expect(transport.accept_inbound_chat(7), "First inbound chat should be accepted.")
	transport.accept_inbound_chat(7)
	transport.accept_inbound_chat(7)
	_expect(not transport.accept_inbound_chat(7), "Inbound chat should be rate-limited per participant.")
	transport.free()


func _test_profile_sanitization() -> void:
	_expect(LocalProfile.sanitize_display_name(" [Admin]\n ") == "Admin", "Display names should be plain and single-line.")
	_expect(LocalProfile.sanitize_display_name("  ") == LocalProfile.DEFAULT_NAME, "Blank display names should use the guest fallback.")


func _test_shared_profile_controls() -> void:
	var controls := preload("res://scripts/ui/profile_avatar_controls.gd").new()
	controls.configure(true, true, "Apply")
	add_child(controls)
	await get_tree().process_frame
	controls.set_profile(ProfileStore.current_profile)
	controls.name_edit.text = "Shared UI"
	var submitted := {"ok": false}
	controls.submitted.connect(func(display_name: String, avatar: AvatarDescriptor) -> void:
		submitted["ok"] = display_name == "Shared UI" and avatar.body_id == ProfileStore.current_profile.avatar.body_id
	)
	controls.submit()
	_expect(bool(submitted["ok"]), "Shared profile controls should emit the edited name and selected avatar.")
	controls.queue_free()
	await get_tree().process_frame


func _test_resources() -> void:
	_expect(load("res://resources/activities/lounge_basics.tres") is ActivityDefinition, "Activity definition should load.")
	_expect(load("res://resources/avatars/default_avatar.tres") is AvatarDescriptor, "Default avatar should load.")
	var makehuman_scene := load("res://assets/avatars/makehuman_baseline.glb") as PackedScene
	_expect(makehuman_scene != null, "The approved MakeHuman baseline should import as a scene.")
	if makehuman_scene != null:
		var instance := makehuman_scene.instantiate()
		var skeleton := instance.find_child("GeneralSkeleton", true, false) as Skeleton3D
		var body := instance.find_child("BodyMesh", true, false) as MeshInstance3D
		_expect(skeleton != null and skeleton.get_bone_count() == 53, "The MakeHuman baseline should retain its humanoid skeleton.")
		_expect(skeleton != null and skeleton.find_bone("RightUpperArm") >= 0, "The MakeHuman skeleton should use normalized humanoid bone names.")
		_expect(body != null and body.get_aabb().size.y > 1.6 and body.get_aabb().size.y < 1.8, "The MakeHuman baseline should remain human-scale.")
		var profile_text := FileAccess.get_file_as_string("res://dev/blender/retarget_profiles/humanoid_profiles.json")
		var profiles := JSON.parse_string(profile_text) as Dictionary
		var target_profile := profiles.get("target_profile", {}) as Dictionary
		var target_bones := target_profile.get("bones", {}) as Dictionary
		_expect(not target_bones.is_empty(), "The avatar retarget profile should define canonical target bones.")
		var target_map := load("res://resources/avatars/makehuman_game_engine_bone_map.tres") as BoneMap
		_expect(target_map != null and target_map.profile is SkeletonProfileHumanoid, "The baseline should retain its humanoid import map.")
		_expect(target_map != null and target_map.get_skeleton_bone_name(&"RightUpperArm") == &"upperarm_r", "The baseline import map should preserve its raw MPFB source-bone contract.")
		instance.free()
	var wardrobe_scene := load("res://assets/avatars/makehuman_wardrobe_proof.glb") as PackedScene
	_expect(wardrobe_scene != null, "The approved MakeHuman wardrobe proof should import as a scene.")
	if wardrobe_scene != null:
		var wardrobe := wardrobe_scene.instantiate()
		var wardrobe_skeleton := wardrobe.find_child("GeneralSkeleton", true, false) as Skeleton3D
		var wardrobe_meshes := wardrobe.find_children("*", "MeshInstance3D", true, false)
		_expect(wardrobe_skeleton != null and wardrobe_skeleton.get_bone_count() == 53, "The wardrobe proof should use the normalized humanoid skeleton.")
		_expect(wardrobe_meshes.size() == 5, "The wardrobe proof should contain body, eyes, hair, outfit, and shoes meshes.")
		wardrobe.free()
	var animation_scene := load("res://assets/animations/quaternius_ual_standard/UAL1_Standard.glb") as PackedScene
	_expect(animation_scene != null, "The approved Quaternius animation library should import as a scene.")
	if animation_scene != null:
		var animation_source := animation_scene.instantiate()
		var players := animation_source.find_children("*", "AnimationPlayer", true, false)
		var animation_player := players[0] as AnimationPlayer if not players.is_empty() else null
		_expect(animation_player != null and animation_player.get_animation_list().size() == 43, "The Quaternius source should expose all 43 Standard actions.")
		animation_source.free()


func _test_project_configuration() -> void:
	_expect(str(ProjectSettings.get_setting("fusion/connection/app_id", "")).is_empty(), "Tracked Fusion App ID should remain empty.")
	for action in ["move_forward", "move_back", "move_left", "move_right", "jump", "sprint", "interact", "primary_action", "toggle_view", "open_chat", "open_emotes", "toggle_room_menu"]:
		_expect(InputMap.has_action(action), "Input action should exist: %s" % action)
	var exports := ConfigFile.new()
	_expect(exports.load("res://export_presets.cfg") == OK, "Export presets should parse.")
	_expect(str(exports.get_value("preset.0", "name", "")) == "Linux", "Linux export preset should exist.")
	_expect(str(exports.get_value("preset.1", "name", "")) == "Windows Desktop", "Windows export preset should exist.")


func _test_isolated_storage_configuration() -> void:
	var isolated_root := OS.get_environment("VIRTUAL_MEETUP_USER_DATA_DIR").strip_edges().replace("\\", "/")
	if isolated_root.is_empty():
		return
	_expect(ProfileStore.profile_path.begins_with(isolated_root), "Profile tests should use isolated storage.")
	_expect(SettingsStore.settings_path.begins_with(isolated_root), "Settings tests should use isolated storage.")


func _test_network_state_codec() -> void:
	var transport := FusionSessionTransport.new()
	transport.local_player_id = 1
	var result := {"received": false, "count": 0}
	transport.prop_state_received.connect(func(prop_id: StringName, value_transform: Transform3D, linear_velocity: Vector3, _angular_velocity: Vector3) -> void:
		result["count"] = int(result["count"]) + 1
		result["received"] = prop_id == &"ball_0" and value_transform.origin.is_equal_approx(Vector3(1.0, 2.0, 3.0)) and linear_velocity.is_equal_approx(Vector3(4.0, 5.0, 6.0))
	)
	var packed := str(transport.call("_pack_prop_state", 2, 1, Transform3D(Basis.IDENTITY, Vector3(1.0, 2.0, 3.0)), Vector3(4.0, 5.0, 6.0), Vector3.ONE))
	transport.call("_observe_prop_property", &"ball_0", packed)
	transport.call("_observe_prop_property", &"ball_0", packed)
	_expect(bool(result["received"]), "Late-join prop state should round-trip through the bounded room-property codec.")
	_expect(int(result["count"]) == 1, "Duplicate late-join prop packets should be ignored.")
	transport.free()


func _test_prop_state_rejects_stale_revisions() -> void:
	var transport := FusionSessionTransport.new()
	transport.local_player_id = 1
	var result := {"count": 0, "x": 0.0}
	transport.prop_state_received.connect(func(_prop_id: StringName, value_transform: Transform3D, _linear_velocity: Vector3, _angular_velocity: Vector3) -> void:
		result["count"] = int(result["count"]) + 1
		result["x"] = value_transform.origin.x
	)
	var first := str(transport.call("_pack_prop_state", 2, 1, Transform3D(Basis.IDENTITY, Vector3(1.0, 0.0, 0.0)), Vector3.ZERO, Vector3.ZERO))
	var newer := str(transport.call("_pack_prop_state", 2, 2, Transform3D(Basis.IDENTITY, Vector3(2.0, 0.0, 0.0)), Vector3.ZERO, Vector3.ZERO))
	transport.call("_observe_prop_property", &"block_0", newer)
	transport.call("_observe_prop_property", &"block_0", first)
	_expect(int(result["count"]) == 1, "Stale prop revisions from the same sender should be ignored.")
	_expect(is_equal_approx(float(result["x"]), 2.0), "The newest accepted prop revision should remain authoritative.")
	transport.free()


func _test_prop_state_uses_shared_live_packet() -> void:
	var transport := FusionSessionTransport.new()
	transport.local_player_id = 1
	var result := {"received": false}
	transport.prop_state_received.connect(func(prop_id: StringName, value_transform: Transform3D, _linear_velocity: Vector3, _angular_velocity: Vector3) -> void:
		result["received"] = prop_id == &"die_0" and value_transform.origin.is_equal_approx(Vector3(0.0, 3.0, 0.0))
	)
	var packed := str(transport.call("_pack_prop_state", 3, 4, Transform3D(Basis.IDENTITY, Vector3(0.0, 3.0, 0.0)), Vector3.ZERO, Vector3.ZERO))
	transport.fusion_receive_prop_state("die_0", packed)
	_expect(bool(result["received"]), "Live prop RPC should use the same bounded packet codec as late-join state.")
	transport.free()


func _test_participant_rejoin_clears_departed_state() -> void:
	var transport := FusionSessionTransport.new()
	transport.call("_on_player_left", 42)
	_expect(transport._departed_player_ids.has(42), "Departed participant IDs should be tracked after leave.")
	transport.call("_on_player_joined", 42, "")
	_expect(not transport._departed_player_ids.has(42), "A rejoining participant should clear stale departed state.")
	transport.free()


func _test_hud_participant_row_replacement() -> void:
	var hud := RoomHUD.new()
	add_child(hud)
	await get_tree().process_frame
	var first := _make_participant(2, "Guest One")
	var second := _make_participant(2, "Guest Two")
	hud.upsert_participant(first)
	hud.upsert_participant(second)
	_expect(hud._participant_rows.size() == 1, "HUD should keep one row per participant after replacement.")
	_expect(hud.people_list.get_child_count() == 1, "HUD should remove replaced participant rows immediately.")
	hud.remove_participant(2)
	_expect(hud._participant_rows.is_empty(), "HUD should forget removed participant rows immediately.")
	_expect(hud.people_list.get_child_count() == 0, "HUD should remove participant row nodes immediately.")
	hud.queue_free()
	await get_tree().process_frame


func _test_settings_round_trip() -> void:
	var original_sensitivity: float = SettingsStore.mouse_sensitivity
	var original_fov: float = SettingsStore.field_of_view
	var original_volume: float = SettingsStore.master_volume
	SettingsStore.set_mouse_sensitivity(99.0)
	SettingsStore.set_field_of_view(-10.0)
	SettingsStore.set_master_volume(2.0)
	_expect(is_equal_approx(SettingsStore.mouse_sensitivity, 0.01), "Sensitivity should clamp malformed values.")
	_expect(is_equal_approx(SettingsStore.field_of_view, 60.0), "FOV should clamp malformed values.")
	_expect(is_equal_approx(SettingsStore.master_volume, 1.0), "Volume should clamp malformed values.")
	SettingsStore.set_mouse_sensitivity(original_sensitivity)
	SettingsStore.set_field_of_view(original_fov)
	SettingsStore.set_master_volume(original_volume)
	SettingsStore.load_settings()
	_expect(is_equal_approx(SettingsStore.field_of_view, original_fov), "Settings should survive a round trip.")


func _test_profile_round_trip() -> void:
	var original_name: String = ProfileStore.current_profile.display_name
	var original_avatar: AvatarDescriptor = ProfileStore.current_profile.avatar.duplicate_descriptor()
	var test_avatar := AvatarDescriptor.new()
	test_avatar.body_id = &"body_tall"
	test_avatar.skin_id = &"skin_deep"
	test_avatar.hair_id = &"hair_bun"
	test_avatar.outfit_id = &"outfit_violet"
	test_avatar.accessory_id = &"badge"
	ProfileStore.update_profile("Round Trip", test_avatar)
	ProfileStore.load_profile()
	_expect(ProfileStore.current_profile.display_name == "Round Trip", "Profile name should survive a round trip.")
	_expect(ProfileStore.current_profile.avatar.hair_id == &"hair_bun", "Avatar IDs should survive a round trip.")
	ProfileStore.update_profile(original_name, original_avatar)


func _test_runtime_nodes() -> void:
	_test_live_customization()
	var player_scene := load("res://scenes/player/player.tscn") as PackedScene
	var clubhouse_scene := load("res://scenes/venues/clubhouse.tscn") as PackedScene
	var player := player_scene.instantiate() as MeetupPlayerController
	var clubhouse := clubhouse_scene.instantiate() as Clubhouse
	add_child(clubhouse)
	add_child(player)
	_expect(player.avatar_visual != null and player.camera != null, "Player runtime components should initialize.")
	_expect(player.avatar_visual != null and player.avatar_visual.uses_authored_visual(), "Players should use the authored MPFB avatar by default.")
	if player.avatar_visual != null:
		var authored_body := player.avatar_visual.get_node_or_null("AuthoredBody") as Node3D
		_expect(authored_body != null and is_equal_approx(absf(authored_body.rotation.y), PI), "The authored avatar should face the controller's negative-Z forward direction.")
		player.avatar_visual.animate_motion(4.3, true, 1.0 / 60.0)
		_expect(player.avatar_visual.current_animation() == &"Walk", "The authored avatar should select its normalized walk animation.")
	player.adjust_third_person_zoom(-1.0)
	_expect(is_equal_approx(player.spring_arm.spring_length, 3.55), "Third-person wheel-up should move the camera closer.")
	var wheel_event := InputEventMouseButton.new()
	wheel_event.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel_event.pressed = true
	wheel_event.factor = 1.0
	player.input_source._unhandled_input(wheel_event)
	var wheel_command := player.input_source.sample_command()
	_expect(is_equal_approx(wheel_command.camera_zoom, 1.0), "The input source should preserve third-person mouse-wheel steps in PlayerCommand.")
	player.set_first_person(true)
	player.adjust_third_person_zoom(1.0)
	_expect(is_equal_approx(player.spring_arm.spring_length, 0.05), "First-person view should ignore wheel zoom.")
	player.set_first_person(false)
	_expect(is_equal_approx(player.spring_arm.spring_length, 3.55), "Returning to third person should restore its zoom distance.")
	player.rotation.y = 0.0
	player.camera_yaw = 0.0
	player.camera_pivot.rotation.y = 0.0
	player._process_look(Vector2(100.0, 0.0))
	_expect(is_equal_approx(player.rotation.y, 0.0), "Third-person free-look should not rotate an idle character.")
	var orbit_world_yaw := player.rotation.y + player.camera_pivot.rotation.y
	_expect(not is_zero_approx(orbit_world_yaw), "Third-person free-look should orbit the camera around an idle character.")
	player._orient_character_to_movement(Vector3.RIGHT, 1.0)
	_expect(is_equal_approx(player.rotation.y, -PI * 0.5), "A moving character should orient toward its world-space travel direction.")
	_expect(is_equal_approx(player.rotation.y + player.camera_pivot.rotation.y, orbit_world_yaw), "Character turning should preserve the third-person camera's world yaw.")
	player.camera_yaw = -PI * 0.5
	var camera_forward := player._camera_relative_movement(Vector2(0.0, -1.0))
	_expect(camera_forward.is_equal_approx(Vector3.RIGHT), "Forward movement should follow the third-person camera's facing direction.")
	_expect(clubhouse.props_by_id.size() == 12, "Clubhouse should register balls, blocks, and dice.")
	player.queue_free()
	clubhouse.queue_free()


func _test_offline_room_bootstrap() -> void:
	var app := await _spawn_offline_app()
	_expect(app.state == AppController.AppState.LOCAL_ROOM, "Offline action should enter the local clubhouse.")
	_expect(app.active_session is OfflineSessionTransport, "Offline flow should use the offline transport.")
	_expect(app.room_root != null and app.room_root.get_node_or_null("Venue") is Clubhouse, "Offline room should create the clubhouse venue.")
	_expect(app.player != null and app.player.name == "LocalPlayer", "Offline room should create a local player.")
	_expect(app.hud != null and app.hud.code_label.text == "Room: OFFLINE", "Offline room should create a HUD with the offline room code.")
	_expect(app.hud != null and app.hud._participant_rows.has(1), "Offline HUD should show the local participant row.")
	await _test_menu_animation_updates(app)
	await _destroy_app(app)


func _test_offline_chat_loop() -> void:
	var app := await _spawn_offline_app()
	app.hud.chat_submitted.emit("  hello clubhouse  ")
	await get_tree().process_frame
	var chat_text := app.hud.chat_log.get_parsed_text()
	_expect(chat_text.contains(ProfileStore.current_profile.display_name), "Offline chat should use the local profile display name.")
	_expect(chat_text.contains("hello clubhouse"), "Offline chat should append the sanitized local message to the HUD.")
	await _destroy_app(app)


func _test_offline_emote_loop() -> void:
	var app := await _spawn_offline_app()
	app.hud.emote_selected.emit(&"wave")
	await get_tree().process_frame
	_expect(app.player.avatar_visual._active_emote == &"wave", "Offline HUD emote selection should play on the local avatar.")
	await _destroy_app(app)


func _test_offline_interaction_loop() -> void:
	var app := await _spawn_offline_app()
	var venue := app.room_root.get_node_or_null("Venue") as Clubhouse
	var seat := venue.get_node_or_null("Seat0") as MeetupSeat if venue != null else null
	_expect(seat != null, "Offline clubhouse should expose a seat interaction.")
	if seat != null:
		seat.interact(app.player)
		await get_tree().process_frame
		_expect(app.player.seated_at != null, "Offline player should be able to sit through an interaction.")
		_expect(seat.get_interaction_prompt(app.player) == "E  Stand", "Occupied local seat should prompt the player to stand.")
		seat.interact(app.player)
		await get_tree().process_frame
		_expect(app.player.seated_at == null, "Offline player should be able to stand through the same interaction.")
	await _destroy_app(app)


func _test_offline_leave_loop() -> void:
	var app := await _spawn_offline_app()
	app.hud.leave_requested.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(app.state == AppController.AppState.HOME, "Offline leave should return to the home state.")
	_expect(app.home_screen != null, "Offline leave should recreate the home screen.")
	_expect(app.active_session == null, "Offline leave should clear the active session.")
	_expect(app.player == null and app.hud == null and app.room_root == null, "Offline leave should clear room-only nodes.")
	await _destroy_app(app)


func _test_remote_avatar_placeholder_replacement() -> void:
	var app := await _spawn_offline_app()
	var snapshot := _make_participant(22, "Remote Friend")
	app.call("_on_participant_upsert", snapshot)
	await get_tree().process_frame
	var placeholder := app.remote_avatars.get(22) as AvatarVisual
	_expect(placeholder != null and placeholder.get_parent() == app.room_root, "Remote participant upsert should create a standalone placeholder avatar before spawn.")
	var network_player := MeetupPlayerController.new()
	app.room_root.add_child(network_player)
	await get_tree().process_frame
	app.state = AppController.AppState.ONLINE_ROOM
	app.call("_on_network_player_spawned", network_player, false, 22)
	await get_tree().process_frame
	_expect(app.remote_avatars.get(22) == network_player.avatar_visual, "Network spawn should replace the placeholder with the network avatar.")
	_expect(not is_instance_valid(placeholder) or placeholder.get_parent() == null, "Network spawn should remove the old standalone placeholder avatar.")
	await _destroy_app(app)


func _test_remote_avatar_cleanup() -> void:
	var app := await _spawn_offline_app()
	var snapshot := _make_participant(23, "Leaving Friend")
	app.call("_on_participant_upsert", snapshot)
	await get_tree().process_frame
	var placeholder := app.remote_avatars.get(23) as AvatarVisual
	app.call("_on_participant_removed", 23)
	await get_tree().process_frame
	_expect(not app.remote_avatars.has(23), "Participant removal should forget the remote avatar entry.")
	_expect(not app.hud._participant_rows.has(23), "Participant removal should clear the HUD row.")
	_expect(not is_instance_valid(placeholder) or placeholder.get_parent() == null, "Participant removal should remove standalone remote avatars.")
	await _destroy_app(app)


func _spawn_offline_app() -> AppController:
	var app := AppController.new()
	add_child(app)
	await get_tree().process_frame
	app.call("_start_offline")
	await get_tree().process_frame
	await get_tree().process_frame
	return app


func _destroy_app(app: AppController) -> void:
	if app != null and is_instance_valid(app):
		app.queue_free()
	await get_tree().process_frame


func _make_participant(player_id: int, display_name: String, is_local := false) -> ParticipantSnapshot:
	var snapshot := ParticipantSnapshot.new()
	snapshot.player_id = player_id
	snapshot.profile_id = "profile-%d" % player_id
	snapshot.display_name = display_name
	snapshot.avatar = AvatarDescriptor.new()
	snapshot.is_local = is_local
	snapshot.is_master = player_id == 1
	return snapshot


func _test_live_customization() -> void:
	for screen: CanvasLayer in [HomeScreen.new(), RoomHUD.new()]:
		add_child(screen)
		var submissions: Array[AvatarDescriptor] = []
		screen.profile_submitted.connect(func(_display_name: String, value: AvatarDescriptor) -> void: submissions.append(value))
		screen.set_profile(LocalProfile.new())
		_expect(submissions.is_empty(), "Loading a profile should not save it again.")
		var controls = screen.avatar_controls if screen is HomeScreen else screen.profile_controls
		var selector: OptionButton = controls._outfit_select
		var selected_index := AvatarDescriptor.OUTFIT_IDS.find(&"outfit_cream")
		selector.select(selected_index)
		selector.item_selected.emit(selected_index)
		_expect(submissions.size() == 1 and submissions[0].outfit_id == &"outfit_cream", "An outfit selection should immediately submit exactly one profile update.")
		var preview: AvatarPreview = controls.avatar_preview
		_expect(preview.avatar.uses_authored_visual() and preview.avatar.descriptor.outfit_id == &"outfit_cream", "Customization should immediately preview the authored outfit.")
		var body := preview.avatar.get_node("AuthoredBody")
		var changed := preview.avatar.descriptor.duplicate_descriptor()
		changed.hair_id = &"hair_bald"
		preview.apply_descriptor(changed)
		_expect(preview.avatar.get_node("AuthoredBody") == body, "Changing appearance should preserve the animated avatar instance.")
		var suit_found := false
		for child: Node in body.find_children("*", "MeshInstance3D", true, false):
			var mesh := child as MeshInstance3D
			if str(mesh.name).contains("short01"):
				_expect(not mesh.visible, "Bald selection should hide the authored hair mesh.")
			if str(mesh.name).contains("casualsuit"):
				suit_found = true
				var material := mesh.get_surface_override_material(0) as StandardMaterial3D
				_expect(material != null and material.albedo_color == AvatarVisual.OUTFIT_COLORS[&"outfit_cream"], "Outfit color should reach the authored suit material.")
				_expect(material != mesh.mesh.surface_get_material(0), "Customization must not mutate shared source materials.")
		_expect(suit_found, "The customization preview should include the authored suit.")
		screen.free()


func _test_menu_animation_updates(app: AppController) -> void:
	var player := app.player
	# Let the actual clubhouse collision settle the player at its spawn.
	for frame in 90:
		await get_tree().physics_frame
		await get_tree().process_frame
	player.velocity.x = MeetupPlayerController.WALK_SPEED
	player.avatar_visual.animate_motion(MeetupPlayerController.WALK_SPEED, true, 0.016)
	app.call("_toggle_room_menu")
	_expect(player.input_suppressed, "Opening the room menu should suppress player commands.")
	for frame in 45:
		await get_tree().physics_frame
		await get_tree().process_frame
	_expect(player.avatar_visual.current_animation() == &"Idle", "Walking should transition to idle after stopping with the menu open.")
	app.call("_toggle_room_menu")
	player.velocity.y = MeetupPlayerController.JUMP_VELOCITY
	await get_tree().physics_frame
	await get_tree().process_frame
	app.call("_toggle_room_menu")
	for frame in 10:
		await get_tree().physics_frame
		await get_tree().process_frame
	_expect(not player.is_on_floor(), "The player should remain airborne briefly after opening a menu mid-jump.")
	_expect(player.avatar_visual.current_animation() == &"Jump", "The airborne animation should still update with the menu open.")
	for frame in 90:
		await get_tree().physics_frame
		await get_tree().process_frame
	_expect(player.is_on_floor(), "The player should land while the menu remains open.")
	_expect(player.avatar_visual.current_animation() == &"Idle", "Landing should transition to idle while the menu remains open.")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
