extends Node

signal profile_changed(profile: LocalProfile)

const SCHEMA_VERSION := 1
const PROFILE_FILE := "profile.cfg"
const DEFAULT_PROFILE_PATH := "user://profile.cfg"
const USER_DATA_ENVIRONMENT_VARIABLE := "VIRTUAL_MEETUP_USER_DATA_DIR"

var current_profile: LocalProfile
var profile_path: String = DEFAULT_PROFILE_PATH


func _ready() -> void:
	_configure_storage_path()
	load_profile()


func load_profile() -> LocalProfile:
	var profile := LocalProfile.new()
	var config := ConfigFile.new()
	if config.load(profile_path) == OK:
		profile.profile_id = str(config.get_value("profile", "id", ""))
		profile.display_name = str(config.get_value("profile", "display_name", LocalProfile.DEFAULT_NAME))
		profile.avatar = AvatarDescriptor.from_dictionary({
			"body": config.get_value("avatar", "body", AvatarDescriptor.BODY_IDS[0]),
			"skin": config.get_value("avatar", "skin", AvatarDescriptor.SKIN_IDS[0]),
			"hair": config.get_value("avatar", "hair", AvatarDescriptor.HAIR_IDS[0]),
			"outfit": config.get_value("avatar", "outfit", AvatarDescriptor.OUTFIT_IDS[0]),
			"accessory": config.get_value("avatar", "accessory", AvatarDescriptor.ACCESSORY_IDS[0]),
		})
	if profile.profile_id.is_empty():
		profile.profile_id = _generate_profile_id()
	profile.sanitize()
	current_profile = profile
	save_profile()
	return current_profile


func update_profile(display_name: String, avatar: AvatarDescriptor) -> void:
	current_profile.display_name = display_name
	current_profile.avatar = avatar.duplicate_descriptor()
	current_profile.sanitize()
	save_profile()
	profile_changed.emit(current_profile)


func save_profile() -> Error:
	if current_profile == null:
		return ERR_UNCONFIGURED
	var config := ConfigFile.new()
	config.set_value("meta", "schema_version", SCHEMA_VERSION)
	config.set_value("profile", "id", current_profile.profile_id)
	config.set_value("profile", "display_name", current_profile.display_name)
	var avatar := current_profile.avatar
	config.set_value("avatar", "body", str(avatar.body_id))
	config.set_value("avatar", "skin", str(avatar.skin_id))
	config.set_value("avatar", "hair", str(avatar.hair_id))
	config.set_value("avatar", "outfit", str(avatar.outfit_id))
	config.set_value("avatar", "accessory", str(avatar.accessory_id))
	return config.save(profile_path)


func _configure_storage_path() -> void:
	var override_root := OS.get_environment(USER_DATA_ENVIRONMENT_VARIABLE).strip_edges().replace("\\", "/")
	if override_root.is_empty():
		profile_path = DEFAULT_PROFILE_PATH
		return
	DirAccess.make_dir_recursive_absolute(override_root)
	profile_path = override_root.path_join(PROFILE_FILE)


func _generate_profile_id() -> String:
	var random_bytes := Crypto.new().generate_random_bytes(16)
	if random_bytes.size() == 16:
		return random_bytes.hex_encode()
	return "%x-%x" % [Time.get_unix_time_from_system(), randi()]
