class_name AppController
extends Node

enum AppState {
	HOME,
	LOCAL_ROOM,
	CONNECTING,
	ONLINE_ROOM,
}

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const CLUBHOUSE_SCENE := preload("res://scenes/venues/clubhouse.tscn")
const GALLERY_SCENE := preload("res://scenes/gallery/avatar_gallery.tscn")

var state: AppState = AppState.HOME
var home_screen: HomeScreen
var room_root: Node3D
var player: MeetupPlayerController
var hud: RoomHUD
var active_session: SessionTransport
var online_session: FusionSessionTransport
var remote_avatars: Dictionary = {}
var pending_gallery: bool = false


func _ready() -> void:
	online_session = FusionSessionTransport.new()
	online_session.name = "FusionSession"
	add_child(online_session)
	online_session.network_player_spawned.connect(_on_network_player_spawned)
	_show_home()


func _show_home() -> void:
	state = AppState.HOME
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if room_root != null:
		room_root.queue_free()
		room_root = null
	if hud != null:
		hud.queue_free()
		hud = null
	player = null
	remote_avatars.clear()
	home_screen = HomeScreen.new()
	home_screen.name = "HomeScreen"
	add_child(home_screen)
	home_screen.set_profile(ProfileStore.current_profile)
	home_screen.offline_requested.connect(_start_offline)
	home_screen.gallery_requested.connect(_start_gallery)
	home_screen.create_requested.connect(_create_online_room)
	home_screen.join_requested.connect(_join_online_room)
	home_screen.profile_submitted.connect(_update_profile)
	_bind_session_status(online_session)


func _start_offline() -> void:
	pending_gallery = false
	var session := OfflineSessionTransport.new()
	add_child(session)
	_bind_session(session)
	active_session = session
	session.start_local(ProfileStore.current_profile)


func _start_gallery() -> void:
	pending_gallery = true
	var session := OfflineSessionTransport.new()
	add_child(session)
	_bind_session(session)
	active_session = session
	session.start_local(ProfileStore.current_profile)


func _create_online_room(region: StringName) -> void:
	pending_gallery = false
	state = AppState.CONNECTING
	active_session = online_session
	_bind_session(online_session)
	online_session.configure_profile(ProfileStore.current_profile)
	online_session.create_room(region)


func _join_online_room(code: String) -> void:
	pending_gallery = false
	state = AppState.CONNECTING
	active_session = online_session
	_bind_session(online_session)
	online_session.configure_profile(ProfileStore.current_profile)
	online_session.join_room(code)


func _bind_session(session: SessionTransport) -> void:
	_bind_session_status(session)
	_connect_once(session.room_joined, _on_room_joined)
	_connect_once(session.room_left, _on_room_left)
	_connect_once(session.room_lock_changed, _on_room_lock_changed)
	_connect_once(session.participant_added, _on_participant_upsert)
	_connect_once(session.participant_updated, _on_participant_upsert)
	_connect_once(session.participant_removed, _on_participant_removed)
	_connect_once(session.chat_received, _on_chat_received)
	_connect_once(session.emote_received, _on_emote_received)
	_connect_once(session.pose_received, _on_pose_received)
	_connect_once(session.prop_state_received, _on_prop_state_received)


func _bind_session_status(session: SessionTransport) -> void:
	_connect_once(session.status_changed, _on_status_changed)


func _on_room_joined(code: String) -> void:
	state = AppState.LOCAL_ROOM if active_session is OfflineSessionTransport else AppState.ONLINE_ROOM
	if home_screen != null:
		home_screen.queue_free()
		home_screen = null
	room_root = Node3D.new()
	room_root.name = "Room"
	add_child(room_root)
	var venue: Node3D = GALLERY_SCENE.instantiate() if pending_gallery else CLUBHOUSE_SCENE.instantiate()
	venue.name = "Venue"
	if venue is Clubhouse:
		(venue as Clubhouse).prop_registered.connect(_on_prop_registered)
		(venue as Clubhouse).die_result.connect(_on_activity_message)
	room_root.add_child(venue)
	if state == AppState.LOCAL_ROOM:
		player = PLAYER_SCENE.instantiate() as MeetupPlayerController
		player.name = "LocalPlayer"
		player.position = Vector3(0.0, 1.0, 5.0 if not pending_gallery else 7.0)
		room_root.add_child(player)
		_configure_local_player(player)
	hud = RoomHUD.new()
	hud.name = "RoomHUD"
	add_child(hud)
	hud.set_room_code(code)
	hud.set_profile(ProfileStore.current_profile)
	hud.set_status("Avatar Gallery" if pending_gallery else ("Offline clubhouse" if state == AppState.LOCAL_ROOM else "Connected to %s" % code))
	hud.chat_submitted.connect(_send_chat)
	hud.emote_selected.connect(_play_emote)
	hud.leave_requested.connect(_leave_room)
	hud.lock_changed.connect(active_session.set_room_locked)
	hud.profile_submitted.connect(_update_profile)
	hud.player_block_changed.connect(active_session.set_player_blocked)
	if player != null:
		hud.modal_visibility_changed.connect(player.set_input_suppressed)
	for participant in active_session.participants.values():
		_on_participant_upsert(participant as ParticipantSnapshot)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _configure_local_player(value: MeetupPlayerController) -> void:
	player = value
	player.set_local_controlled(true)
	player.set_profile_avatar(ProfileStore.current_profile.avatar)
	player.prompt_changed.connect(_on_prompt_changed)
	player.chat_requested.connect(_open_chat)
	player.emotes_requested.connect(_toggle_emotes)
	player.menu_requested.connect(_toggle_room_menu)
	player.cancel_requested.connect(_close_or_leave)
	player.emote_requested.connect(_send_emote)
	player.pose_ready.connect(_publish_pose)
	if hud != null and not hud.modal_visibility_changed.is_connected(player.set_input_suppressed):
		hud.modal_visibility_changed.connect(player.set_input_suppressed)


func _on_network_player_spawned(network_player: MeetupPlayerController, is_local: bool, owner_id: int) -> void:
	if state != AppState.ONLINE_ROOM:
		return
	if is_local:
		network_player.name = "LocalNetworkPlayer"
		_configure_local_player(network_player)
		return
	network_player.name = "RemoteNetworkPlayer%d" % owner_id
	_remove_standalone_remote_avatar(owner_id)
	remote_avatars[owner_id] = network_player.avatar_visual
	var snapshot := active_session.participants.get(owner_id) as ParticipantSnapshot
	if snapshot != null:
		network_player.set_profile_avatar(snapshot.avatar)


func _on_room_left() -> void:
	if active_session != null and active_session != online_session:
		active_session.queue_free()
	active_session = null
	_show_home()


func _leave_room() -> void:
	if active_session != null:
		active_session.leave_room()
	else:
		_show_home()


func _update_profile(display_name: String, avatar: AvatarDescriptor) -> void:
	ProfileStore.update_profile(display_name, avatar)
	if home_screen != null:
		home_screen.set_profile(ProfileStore.current_profile)
	if player != null:
		player.set_profile_avatar(ProfileStore.current_profile.avatar)
	if hud != null:
		hud.set_profile(ProfileStore.current_profile)
	if active_session != null:
		active_session.configure_profile(ProfileStore.current_profile)


func _on_status_changed(message: String, connecting: bool) -> void:
	if home_screen != null:
		home_screen.set_status(message, connecting)
	if hud != null:
		hud.set_status(message)
	if state == AppState.CONNECTING and not connecting and active_session != null and active_session.state == SessionTransport.State.IDLE:
		state = AppState.HOME


func _on_prompt_changed(prompt: String) -> void:
	if hud != null:
		hud.set_prompt(prompt)


func _open_chat() -> void:
	if hud != null:
		hud.open_chat()


func _toggle_emotes() -> void:
	if hud != null:
		hud.toggle_emotes()


func _toggle_room_menu() -> void:
	if hud != null:
		hud.toggle_menu()


func _close_or_leave() -> void:
	if hud != null and hud.close_modals():
		return
	if hud != null:
		hud.toggle_menu()


func _send_chat(message: String) -> void:
	if active_session != null and not active_session.send_chat(message) and hud != null:
		hud.set_status("Chat is empty or temporarily rate-limited.")


func _play_emote(emote_id: StringName) -> void:
	if player != null:
		player.play_emote(emote_id, true)


func _send_emote(emote_id: StringName, active: bool) -> void:
	if active_session != null:
		active_session.send_emote(emote_id, active)


func _on_chat_received(player_id: int, display_name: String, message: String) -> void:
	if active_session != null and active_session.is_player_blocked(player_id):
		return
	if hud != null:
		hud.add_chat(display_name, message)


func _on_emote_received(player_id: int, emote_id: StringName, active: bool) -> void:
	if active_session != null and active_session.is_player_blocked(player_id):
		return
	if player_id == active_session.local_player_id and player != null:
		player.avatar_visual.play_emote(emote_id, active)
	else:
		var avatar := remote_avatars.get(player_id) as AvatarVisual
		if avatar != null:
			avatar.play_emote(emote_id, active)


func _on_participant_upsert(snapshot: ParticipantSnapshot) -> void:
	if hud != null:
		hud.upsert_participant(snapshot)
	if snapshot.is_local or room_root == null:
		return
	var avatar := remote_avatars.get(snapshot.player_id) as AvatarVisual
	if avatar != null and not is_instance_valid(avatar):
		remote_avatars.erase(snapshot.player_id)
		avatar = null
	if avatar != null and avatar.get_parent() is MeetupPlayerController:
		avatar.apply_descriptor(snapshot.avatar)
		return
	if avatar == null:
		avatar = AvatarVisual.new()
		avatar.name = "RemoteAvatar%d" % snapshot.player_id
		avatar.position = Vector3(float(remote_avatars.size()) * 1.5 - 2.0, 0.2, 2.0)
		room_root.add_child(avatar)
		remote_avatars[snapshot.player_id] = avatar
	avatar.apply_descriptor(snapshot.avatar)


func _on_participant_removed(player_id: int) -> void:
	if hud != null:
		hud.remove_participant(player_id)
	_remove_standalone_remote_avatar(player_id)
	remote_avatars.erase(player_id)


func _remove_standalone_remote_avatar(player_id: int) -> void:
	var avatar := remote_avatars.get(player_id) as AvatarVisual
	if avatar != null and is_instance_valid(avatar) and not avatar.get_parent() is MeetupPlayerController:
		avatar.queue_free()


func _on_room_lock_changed(locked: bool) -> void:
	if hud != null:
		hud.set_room_locked(locked)


func _publish_pose(position: Vector3, yaw: float, current_velocity: Vector3) -> void:
	if active_session != null and not active_session is FusionSessionTransport:
		active_session.publish_pose(position, yaw, current_velocity)


func _on_pose_received(player_id: int, position: Vector3, yaw: float, current_velocity: Vector3) -> void:
	var avatar := remote_avatars.get(player_id) as AvatarVisual
	if avatar == null or avatar.get_parent() is MeetupPlayerController:
		return
	avatar.global_position = avatar.global_position.lerp(position, 0.55)
	avatar.rotation.y = lerp_angle(avatar.rotation.y, yaw, 0.55)
	avatar.animate_motion(Vector2(current_velocity.x, current_velocity.z).length(), true, 1.0 / 15.0)


func _on_prop_registered(prop: MeetupGrabbable) -> void:
	prop.state_changed.connect(_on_local_prop_state)


func _on_local_prop_state(prop_id: StringName, value_transform: Transform3D, linear_velocity: Vector3, angular_velocity: Vector3) -> void:
	if active_session != null:
		active_session.publish_prop_state(prop_id, value_transform, linear_velocity, angular_velocity)


func _on_prop_state_received(prop_id: StringName, value_transform: Transform3D, linear_velocity: Vector3, angular_velocity: Vector3) -> void:
	if room_root == null:
		return
	var venue := room_root.get_node_or_null("Venue") as Clubhouse
	if venue != null:
		venue.apply_prop_state(prop_id, value_transform, linear_velocity, angular_velocity)


func _on_activity_message(message: String) -> void:
	if hud != null:
		hud.set_status(message)


func _connect_once(signal_value: Signal, callable: Callable) -> void:
	if not signal_value.is_connected(callable):
		signal_value.connect(callable)
