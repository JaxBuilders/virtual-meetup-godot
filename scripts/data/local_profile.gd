class_name LocalProfile
extends Resource

const DEFAULT_NAME := "Guest"

@export var profile_id: String = ""
@export var display_name: String = DEFAULT_NAME
@export var avatar: AvatarDescriptor = AvatarDescriptor.new()


func sanitize() -> void:
	profile_id = profile_id.strip_edges().left(64)
	display_name = sanitize_display_name(display_name)
	if avatar == null:
		avatar = AvatarDescriptor.new()
	avatar.sanitize()


func to_dictionary() -> Dictionary:
	return {
		"profile_id": profile_id,
		"display_name": display_name,
		"avatar": avatar.to_dictionary(),
	}


static func sanitize_display_name(value: String) -> String:
	var cleaned := value.strip_edges().replace("[", "").replace("]", "")
	cleaned = cleaned.replace("\n", " ").replace("\r", " ").replace("\t", " ")
	while cleaned.contains("  "):
		cleaned = cleaned.replace("  ", " ")
	return cleaned.left(24) if not cleaned.is_empty() else DEFAULT_NAME
