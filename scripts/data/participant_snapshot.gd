class_name ParticipantSnapshot
extends RefCounted

var player_id: int = 0
var profile_id: String = ""
var display_name: String = "Guest"
var avatar: AvatarDescriptor = AvatarDescriptor.new()
var is_local: bool = false
var is_master: bool = false
var is_speaking: bool = false
var is_muted: bool = false
var is_blocked: bool = false


func duplicate_snapshot() -> ParticipantSnapshot:
	var copy := ParticipantSnapshot.new()
	copy.player_id = player_id
	copy.profile_id = profile_id
	copy.display_name = display_name
	copy.avatar = avatar.duplicate_descriptor()
	copy.is_local = is_local
	copy.is_master = is_master
	copy.is_speaking = is_speaking
	copy.is_muted = is_muted
	copy.is_blocked = is_blocked
	return copy
