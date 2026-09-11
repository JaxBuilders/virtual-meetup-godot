class_name VoiceTransport
extends Node

signal availability_changed(available: bool)
signal speaking_changed(player_id: int, speaking: bool)


func is_available() -> bool:
	return false


func get_unavailable_reason() -> String:
	return "Voice is planned for a later milestone."


func connect_to_room(_room_id: String) -> Error:
	return ERR_UNAVAILABLE


func disconnect_from_room() -> void:
	pass


func set_player_muted(_player_id: int, _muted: bool) -> void:
	pass
