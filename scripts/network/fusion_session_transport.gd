class_name FusionSessionTransport
extends SessionTransport

signal network_player_spawned(player: MeetupPlayerController, is_local: bool, owner_id: int)

const NETWORK_PLAYER_SCENE := preload("res://scenes/network/network_player.tscn")
const ROOM_OPTIONS := {
	"max_players": 16,
	"is_visible": false,
	"is_open": true,
	"lobby_properties": ["vm_version"],
	"vm_version": "1",
}
const PROFILE_PREFIX := "profile_"
const PROP_PREFIX := "prop_"
const PROP_PACKET_VERSION := 1
const LOCK_KEY := "room_locked"
const POLL_INTERVAL := 0.35
const JOIN_TIMEOUT := 12.0

var _fusion: Object
var _profile: LocalProfile
var _pending_action: StringName
var _pending_room_name: String
var _pending_region: String
var _poll_cooldown: float = 0.0
var _join_timeout: float = 0.0
var _departed_player_ids: Dictionary = {}
var _participant_fingerprints: Dictionary = {}
var _observed_prop_fingerprints: Dictionary = {}
var _observed_prop_revisions: Dictionary = {}
var _prop_publish_revisions: Dictionary = {}
var _spawner: Node


func _ready() -> void:
	var app_id := OS.get_environment("VIRTUAL_MEETUP_FUSION_APP_ID").strip_edges()
	if not app_id.is_empty():
		ProjectSettings.set_setting("fusion/connection/app_id", app_id)
	if not Engine.has_singleton("Fusion"):
		status_changed.emit("Fusion extension is unavailable; offline play remains available.", false)
		return
	_fusion = Engine.get_singleton("Fusion")
	if not app_id.is_empty() and _fusion.has_method("set_app_id"):
		_fusion.call("set_app_id", app_id)
	_fusion.call("register_broadcast_receiver", self)
	_spawner = ClassDB.instantiate("FusionSpawner") as Node
	if _spawner != null:
		_spawner.name = "PlayerSpawner"
		add_child(_spawner)
		_spawner.set("spawn_path", NodePath("../.."))
		_spawner.call("add_spawnable_scene", NETWORK_PLAYER_SCENE)
		_spawner.connect("spawned", _on_network_player_spawned)
	_connect_if_present("connected_to_photon", _on_connected_to_photon)
	_connect_if_present("connection_failed", _on_connection_failed)
	_connect_if_present("room_joined", _on_room_joined)
	_connect_if_present("room_left", _on_room_left)
	_connect_if_present("player_joined", _on_player_joined)
	_connect_if_present("player_left", _on_player_left)


func _exit_tree() -> void:
	if _fusion != null:
		_fusion.call("unregister_broadcast_receiver", self)


func _process(delta: float) -> void:
	if state == State.CONNECTING:
		_join_timeout = maxf(0.0, _join_timeout - delta)
		if _join_timeout <= 0.0:
			_fail("Connection timed out.")
	if state != State.JOINED or _fusion == null:
		return
	_poll_cooldown = maxf(0.0, _poll_cooldown - delta)
	if _poll_cooldown <= 0.0:
		_poll_cooldown = POLL_INTERVAL
		_poll_room_properties()


func configure_profile(profile: LocalProfile) -> void:
	_profile = profile
	if state == State.JOINED:
		_publish_local_profile()


func is_available() -> bool:
	return _fusion != null and not str(ProjectSettings.get_setting("fusion/connection/app_id", "")).is_empty()


func create_room(region: StringName) -> void:
	if not _begin_online_action():
		return
	room_code = InviteCode.generate(region)
	var parsed := InviteCode.parse(room_code)
	_pending_action = &"create"
	_pending_room_name = str(parsed.get("room_name", ""))
	_pending_region = str(parsed.get("region", ""))
	_connect_or_join()


func join_room(code: String) -> void:
	var parsed := InviteCode.parse(code)
	if parsed.is_empty():
		status_changed.emit("Enter a regional code such as US-7K2M9Q4R.", false)
		return
	if not _begin_online_action():
		return
	room_code = str(parsed["display"])
	_pending_action = &"join"
	_pending_room_name = str(parsed["room_name"])
	_pending_region = str(parsed["region"])
	_connect_or_join()


func leave_room() -> void:
	_pending_action = &""
	if _fusion != null and bool(_fusion.call("is_in_room")):
		var room := _fusion.call("get_room") as Object
		if room != null and local_player_id > 0 and room.has_method("remove_properties"):
			room.call("remove_properties", PackedStringArray([PROFILE_PREFIX + str(local_player_id)]))
		_fusion.call("leave_room")
	elif _fusion != null and bool(_fusion.call("is_connected_to_photon")):
		_fusion.call("disconnect_from_photon")
	else:
		super.leave_room()


func set_room_locked(value: bool) -> void:
	if state != State.JOINED or _fusion == null or not bool(_fusion.call("is_master_client")):
		status_changed.emit("Only the current room master can change admission.", false)
		return
	room_locked = value
	var room := _fusion.call("get_room") as Object
	if room != null:
		room.call("set_property", LOCK_KEY, room_locked)
		if room.has_method("set_is_open"):
			room.call("set_is_open", not room_locked)
		elif room.has_method("set_open"):
			room.call("set_open", not room_locked)
	room_lock_changed.emit(room_locked)


func send_chat(message: String) -> bool:
	var cleaned := sanitize_chat(message)
	if state != State.JOINED or cleaned.is_empty() or not can_send_chat() or _profile == null:
		return false
	remember_chat_send()
	chat_received.emit(local_player_id, _profile.display_name, cleaned)
	_send_rpc(Callable(self, "fusion_receive_chat").bind(local_player_id, _profile.display_name, cleaned))
	return true


func send_emote(emote_id: StringName, active := true) -> bool:
	if state != State.JOINED or not EMOTE_IDS.has(emote_id):
		return false
	_send_rpc(Callable(self, "fusion_receive_emote").bind(local_player_id, str(emote_id), active))
	return true


func publish_pose(position: Vector3, yaw: float, velocity: Vector3) -> void:
	if state == State.JOINED:
		_send_rpc(Callable(self, "fusion_receive_pose").bind(local_player_id, position, yaw, velocity))


func publish_prop_state(prop_id: StringName, transform: Transform3D, linear_velocity: Vector3, angular_velocity: Vector3) -> void:
	if state == State.JOINED:
		var revision := int(_prop_publish_revisions.get(prop_id, 0)) + 1
		_prop_publish_revisions[prop_id] = revision
		var packed := _pack_prop_state(local_player_id, revision, transform, linear_velocity, angular_velocity)
		_send_rpc(Callable(self, "fusion_receive_prop_state").bind(str(prop_id), packed))
		var room := _fusion.call("get_room") as Object
		if room != null:
			room.call("set_property", PROP_PREFIX + str(prop_id), packed)


func fusion_receive_chat(player_id: int, display_name: String, message: String) -> void:
	if player_id == local_player_id or is_player_blocked(player_id) or not accept_inbound_chat(player_id):
		return
	var cleaned_name := LocalProfile.sanitize_display_name(display_name)
	var cleaned_message := sanitize_chat(message)
	if not cleaned_message.is_empty():
		chat_received.emit(player_id, cleaned_name, cleaned_message)


func fusion_receive_emote(player_id: int, emote_id: String, active: bool) -> void:
	var stable_id := StringName(emote_id)
	if not is_player_blocked(player_id) and EMOTE_IDS.has(stable_id):
		emote_received.emit(player_id, stable_id, active)


func fusion_receive_pose(player_id: int, position: Vector3, yaw: float, velocity: Vector3) -> void:
	if player_id != local_player_id:
		pose_received.emit(player_id, position, yaw, velocity)


func fusion_receive_prop_state(prop_id: String, packed: String) -> void:
	_observe_prop_property(StringName(prop_id), packed)


func _begin_online_action() -> bool:
	if _profile == null:
		status_changed.emit("Create a local profile before connecting.", false)
		return false
	if not is_available():
		status_changed.emit("Online rooms need VIRTUAL_MEETUP_FUSION_APP_ID. Offline play is ready.", false)
		return false
	state = State.CONNECTING
	_join_timeout = JOIN_TIMEOUT
	status_changed.emit("Connecting to Photon…", true)
	return true


func _connect_or_join() -> void:
	if bool(_fusion.call("is_connected_to_photon")):
		_join_pending_room()
	else:
		_fusion.call("connect_to_photon", _profile.profile_id, _pending_region, "virtual-meetup-v1")


func _on_connected_to_photon() -> void:
	_join_pending_room()


func _join_pending_room() -> void:
	var options := ROOM_OPTIONS.duplicate(true)
	if _pending_action == &"create":
		_fusion.call("create_room", _pending_room_name, options)
	elif _pending_action == &"join":
		if _fusion.has_method("join_room"):
			_fusion.call("join_room", _pending_room_name, options)
		else:
			_fail("This Fusion snapshot cannot join a named room without creating it.")


func _on_room_joined() -> void:
	state = State.JOINED
	_join_timeout = 0.0
	local_player_id = int(_fusion.call("get_local_player_id"))
	_departed_player_ids.clear()
	_publish_local_profile()
	room_joined.emit(room_code)
	if _spawner != null:
		_spawner.call("spawn", NETWORK_PLAYER_SCENE, _prepare_local_player)
	status_changed.emit("Connected to %s" % room_code, false)


func _on_room_left() -> void:
	local_player_id = 0
	participants.clear()
	_departed_player_ids.clear()
	_participant_fingerprints.clear()
	_observed_prop_fingerprints.clear()
	_observed_prop_revisions.clear()
	_prop_publish_revisions.clear()
	state = State.IDLE
	room_left.emit()
	status_changed.emit("Left online room.", false)


func _on_player_left(player_id: int, _inactive: bool = false) -> void:
	_departed_player_ids[player_id] = true
	if participants.erase(player_id):
		_participant_fingerprints.erase(player_id)
		participant_removed.emit(player_id)


func _on_player_joined(player_id: int, _user_id: String = "") -> void:
	_departed_player_ids.erase(player_id)
	_publish_local_profile()


func _prepare_local_player(node: Node) -> void:
	var network_player := node as MeetupPlayerController
	if network_player != null:
		network_player.global_position = Vector3(0.0, 1.0, 5.0)


func _on_network_player_spawned(node: Node) -> void:
	var network_player := node as MeetupPlayerController
	if network_player != null:
		call_deferred("_classify_network_player", network_player)


func _classify_network_player(network_player: MeetupPlayerController) -> void:
	if not is_instance_valid(network_player):
		return
	var replicator := network_player.get_node_or_null("Replicator")
	if replicator == null:
		return
	var is_local := bool(replicator.call("has_authority"))
	var owner_id := int(replicator.call("get_owner_id"))
	network_player.set_local_controlled(is_local)
	network_player_spawned.emit(network_player, is_local, owner_id)


func _on_connection_failed(error: String) -> void:
	_fail("Connection failed: %s" % error)


func _fail(message: String) -> void:
	state = State.IDLE
	_pending_action = &""
	_join_timeout = 0.0
	status_changed.emit(message, false)


func _publish_local_profile() -> void:
	if _profile == null or _fusion == null or not bool(_fusion.call("is_in_room")):
		return
	var room := _fusion.call("get_room") as Object
	if room != null:
		room.call("set_property", PROFILE_PREFIX + str(local_player_id), JSON.stringify(_profile.to_dictionary()))


func _poll_room_properties() -> void:
	var room := _fusion.call("get_room") as Object
	if room == null:
		return
	var properties := room.call("get_custom_properties") as Dictionary
	var observed_ids: Dictionary = {}
	for key in properties:
		var key_string := str(key)
		if key_string.begins_with(PROP_PREFIX):
			_observe_prop_property(StringName(key_string.trim_prefix(PROP_PREFIX)), str(properties[key]))
			continue
		if not key_string.begins_with(PROFILE_PREFIX):
			continue
		var player_id := key_string.trim_prefix(PROFILE_PREFIX).to_int()
		if player_id <= 0 or _departed_player_ids.has(player_id):
			continue
		observed_ids[player_id] = true
		var decoded: Variant = JSON.parse_string(str(properties[key]))
		if not decoded is Dictionary:
			continue
		var data := decoded as Dictionary
		var snapshot := participants.get(player_id) as ParticipantSnapshot
		var is_new := snapshot == null
		if is_new:
			snapshot = ParticipantSnapshot.new()
		snapshot.player_id = player_id
		snapshot.profile_id = str(data.get("profile_id", "")).left(64)
		snapshot.display_name = LocalProfile.sanitize_display_name(str(data.get("display_name", "Guest")))
		snapshot.avatar = AvatarDescriptor.from_dictionary(data.get("avatar", {}) as Dictionary)
		snapshot.is_local = player_id == local_player_id
		snapshot.is_master = player_id == int(room.call("get_master_client_id")) if room.has_method("get_master_client_id") else false
		snapshot.is_blocked = is_player_blocked(player_id)
		snapshot.is_muted = snapshot.is_blocked
		var fingerprint := "%s|%s|%s|%s" % [snapshot.display_name, JSON.stringify(snapshot.avatar.to_dictionary()), snapshot.is_master, snapshot.is_blocked]
		var changed := str(_participant_fingerprints.get(player_id, "")) != fingerprint
		participants[player_id] = snapshot
		_participant_fingerprints[player_id] = fingerprint
		if is_new:
			participant_added.emit(snapshot.duplicate_snapshot())
		elif changed:
			participant_updated.emit(snapshot.duplicate_snapshot())
	var new_locked := bool(properties.get(LOCK_KEY, false))
	if new_locked != room_locked:
		room_locked = new_locked
		room_lock_changed.emit(room_locked)
	for player_id in participants.keys():
		if not observed_ids.has(player_id):
			participants.erase(player_id)
			_participant_fingerprints.erase(player_id)
			participant_removed.emit(int(player_id))


func _send_rpc(callable: Callable) -> void:
	if _fusion != null and bool(_fusion.call("is_in_room")):
		_fusion.call("rpc", callable)


func _pack_prop_state(sender_id: int, revision: int, value_transform: Transform3D, linear_velocity: Vector3, angular_velocity: Vector3) -> String:
	var rotation := value_transform.basis.get_rotation_quaternion()
	return JSON.stringify({
		"version": PROP_PACKET_VERSION,
		"sender_id": sender_id,
		"revision": revision,
		"origin": [value_transform.origin.x, value_transform.origin.y, value_transform.origin.z],
		"rotation": [rotation.x, rotation.y, rotation.z, rotation.w],
		"linear_velocity": [linear_velocity.x, linear_velocity.y, linear_velocity.z],
		"angular_velocity": [angular_velocity.x, angular_velocity.y, angular_velocity.z],
	})


func _observe_prop_property(prop_id: StringName, packed: String) -> void:
	if str(_observed_prop_fingerprints.get(prop_id, "")) == packed:
		return
	var decoded := _decode_prop_state(packed)
	if decoded.is_empty():
		return
	var sender_id := int(decoded["sender_id"])
	if sender_id == local_player_id:
		return
	var revision := int(decoded["revision"])
	var revision_key := "%s:%d" % [str(prop_id), sender_id]
	if revision <= int(_observed_prop_revisions.get(revision_key, -1)):
		return
	_observed_prop_revisions[revision_key] = revision
	_observed_prop_fingerprints[prop_id] = packed
	var value_transform := decoded["transform"] as Transform3D
	var linear_velocity := decoded["linear_velocity"] as Vector3
	var angular_velocity := decoded["angular_velocity"] as Vector3
	prop_state_received.emit(prop_id, value_transform, linear_velocity, angular_velocity)


func _decode_prop_state(packed: String) -> Dictionary:
	var decoded: Variant = JSON.parse_string(packed)
	if decoded is Dictionary:
		var data := decoded as Dictionary
		if int(data.get("version", 0)) != PROP_PACKET_VERSION:
			return {}
		return _decode_prop_state_values(
			int(data.get("sender_id", 0)),
			int(data.get("revision", 0)),
			data.get("origin", []),
			data.get("rotation", []),
			data.get("linear_velocity", []),
			data.get("angular_velocity", [])
		)
	if decoded is Array:
		var values := decoded as Array
		if values.size() != 14:
			return {}
		return _decode_prop_state_values(
			int(values[0]),
			0,
			[values[1], values[2], values[3]],
			[values[4], values[5], values[6], values[7]],
			[values[8], values[9], values[10]],
			[values[11], values[12], values[13]]
		)
	return {}


func _decode_prop_state_values(sender_id: int, revision: int, origin_value: Variant, rotation_value: Variant, linear_value: Variant, angular_value: Variant) -> Dictionary:
	if sender_id <= 0 or revision < 0 or not origin_value is Array or not rotation_value is Array or not linear_value is Array or not angular_value is Array:
		return {}
	var origin := origin_value as Array
	var rotation := rotation_value as Array
	var linear := linear_value as Array
	var angular := angular_value as Array
	if origin.size() != 3 or rotation.size() != 4 or linear.size() != 3 or angular.size() != 3:
		return {}
	return {
		"sender_id": sender_id,
		"revision": revision,
		"transform": Transform3D(
			Basis(Quaternion(float(rotation[0]), float(rotation[1]), float(rotation[2]), float(rotation[3]))),
			Vector3(float(origin[0]), float(origin[1]), float(origin[2]))
		),
		"linear_velocity": Vector3(float(linear[0]), float(linear[1]), float(linear[2])),
		"angular_velocity": Vector3(float(angular[0]), float(angular[1]), float(angular[2])),
	}


func _connect_if_present(signal_name: StringName, callable: Callable) -> void:
	if _fusion.has_signal(signal_name) and not _fusion.is_connected(signal_name, callable):
		_fusion.connect(signal_name, callable)
