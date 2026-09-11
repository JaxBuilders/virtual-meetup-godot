class_name SessionTransport
extends Node

signal status_changed(message: String, connecting: bool)
signal room_joined(code: String)
signal room_left
signal room_lock_changed(locked: bool)
signal participant_added(participant: ParticipantSnapshot)
signal participant_updated(participant: ParticipantSnapshot)
signal participant_removed(player_id: int)
signal chat_received(player_id: int, display_name: String, message: String)
signal emote_received(player_id: int, emote_id: StringName, active: bool)
signal pose_received(player_id: int, position: Vector3, yaw: float, velocity: Vector3)
signal prop_state_received(prop_id: StringName, transform: Transform3D, linear_velocity: Vector3, angular_velocity: Vector3)

enum State {
	IDLE,
	CONNECTING,
	JOINED,
}

const CHAT_MAX_LENGTH := 280
const CHAT_WINDOW_MSEC := 5000
const CHAT_MESSAGES_PER_WINDOW := 3
const EMOTE_IDS := [&"wave", &"point", &"clap", &"sit", &"dance"]

var state: State = State.IDLE
var room_code: String = ""
var room_locked: bool = false
var local_player_id: int = 0
var participants: Dictionary = {}
var blocked_player_ids: Dictionary = {}
var _recent_chat_times: Array[int] = []
var _inbound_chat_times: Dictionary = {}


func configure_profile(_profile: LocalProfile) -> void:
	pass


func create_room(_region: StringName) -> void:
	status_changed.emit("This transport cannot create an online room.", false)


func join_room(_code: String) -> void:
	status_changed.emit("This transport cannot join an online room.", false)


func leave_room() -> void:
	state = State.IDLE
	room_code = ""
	participants.clear()
	room_left.emit()


func set_room_locked(value: bool) -> void:
	room_locked = value
	room_lock_changed.emit(room_locked)


func send_chat(_message: String) -> bool:
	return false


func send_emote(_emote_id: StringName, _active := true) -> bool:
	return false


func publish_pose(_position: Vector3, _yaw: float, _velocity: Vector3) -> void:
	pass


func publish_prop_state(_prop_id: StringName, _transform: Transform3D, _linear_velocity: Vector3, _angular_velocity: Vector3) -> void:
	pass


func set_player_blocked(player_id: int, blocked: bool) -> void:
	if blocked:
		blocked_player_ids[player_id] = true
	else:
		blocked_player_ids.erase(player_id)
	var participant := participants.get(player_id) as ParticipantSnapshot
	if participant != null:
		participant.is_blocked = blocked
		participant.is_muted = blocked
		participant_updated.emit(participant.duplicate_snapshot())


func is_player_blocked(player_id: int) -> bool:
	return blocked_player_ids.has(player_id)


func can_send_chat() -> bool:
	var now := Time.get_ticks_msec()
	while not _recent_chat_times.is_empty() and now - _recent_chat_times[0] > CHAT_WINDOW_MSEC:
		_recent_chat_times.pop_front()
	return _recent_chat_times.size() < CHAT_MESSAGES_PER_WINDOW


func remember_chat_send() -> void:
	_recent_chat_times.append(Time.get_ticks_msec())


func accept_inbound_chat(player_id: int) -> bool:
	var now := Time.get_ticks_msec()
	var times: Array = _inbound_chat_times.get(player_id, []) as Array
	while not times.is_empty() and now - int(times[0]) > CHAT_WINDOW_MSEC:
		times.pop_front()
	if times.size() >= CHAT_MESSAGES_PER_WINDOW:
		_inbound_chat_times[player_id] = times
		return false
	times.append(now)
	_inbound_chat_times[player_id] = times
	return true


static func sanitize_chat(value: String) -> String:
	var cleaned := value.strip_edges().replace("[", "［").replace("]", "］")
	cleaned = cleaned.replace("\r", " ").replace("\n", " ").replace("\t", " ")
	while cleaned.contains("  "):
		cleaned = cleaned.replace("  ", " ")
	return cleaned.left(CHAT_MAX_LENGTH)
