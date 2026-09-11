class_name OfflineSessionTransport
extends SessionTransport

var _profile: LocalProfile


func configure_profile(profile: LocalProfile) -> void:
	_profile = profile


func start_local(profile: LocalProfile) -> void:
	configure_profile(profile)
	state = State.JOINED
	room_code = "OFFLINE"
	local_player_id = 1
	room_locked = true
	var participant := ParticipantSnapshot.new()
	participant.player_id = local_player_id
	participant.profile_id = profile.profile_id
	participant.display_name = profile.display_name
	participant.avatar = profile.avatar.duplicate_descriptor()
	participant.is_local = true
	participant.is_master = true
	participants[local_player_id] = participant
	participant_added.emit(participant.duplicate_snapshot())
	room_joined.emit(room_code)
	status_changed.emit("Offline clubhouse", false)


func send_chat(message: String) -> bool:
	var cleaned := sanitize_chat(message)
	if cleaned.is_empty() or not can_send_chat() or _profile == null:
		return false
	remember_chat_send()
	chat_received.emit(local_player_id, _profile.display_name, cleaned)
	return true


func send_emote(emote_id: StringName, active := true) -> bool:
	if not EMOTE_IDS.has(emote_id):
		return false
	emote_received.emit(local_player_id, emote_id, active)
	return true


func leave_room() -> void:
	if participants.has(local_player_id):
		participant_removed.emit(local_player_id)
	super.leave_room()
