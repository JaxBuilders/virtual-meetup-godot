class_name ProfileAvatarControls
extends VBoxContainer

signal submitted(display_name: String, avatar: AvatarDescriptor)

var show_name_field: bool = true
var show_avatar_fields: bool = true
var submit_button_text: String = ""

var name_edit: LineEdit
var _body_select: OptionButton
var _skin_select: OptionButton
var _hair_select: OptionButton
var _outfit_select: OptionButton
var _accessory_select: OptionButton
var _current_avatar := AvatarDescriptor.new()


func configure(include_name: bool, include_avatar: bool, submit_text := "") -> void:
	show_name_field = include_name
	show_avatar_fields = include_avatar
	submit_button_text = submit_text


func _ready() -> void:
	_build_controls()


func set_profile(profile: LocalProfile) -> void:
	if name_edit != null:
		name_edit.text = profile.display_name
	set_avatar(profile.avatar)


func set_avatar(avatar: AvatarDescriptor) -> void:
	_current_avatar = avatar.duplicate_descriptor()
	_current_avatar.sanitize()
	_select(_body_select, AvatarDescriptor.BODY_IDS, _current_avatar.body_id)
	_select(_skin_select, AvatarDescriptor.SKIN_IDS, _current_avatar.skin_id)
	_select(_hair_select, AvatarDescriptor.HAIR_IDS, _current_avatar.hair_id)
	_select(_outfit_select, AvatarDescriptor.OUTFIT_IDS, _current_avatar.outfit_id)
	_select(_accessory_select, AvatarDescriptor.ACCESSORY_IDS, _current_avatar.accessory_id)


func get_display_name(fallback := "") -> String:
	return name_edit.text if name_edit != null else fallback


func get_avatar() -> AvatarDescriptor:
	if not show_avatar_fields or _body_select == null:
		return _current_avatar.duplicate_descriptor()
	var avatar := AvatarDescriptor.new()
	avatar.body_id = AvatarDescriptor.BODY_IDS[_body_select.selected]
	avatar.skin_id = AvatarDescriptor.SKIN_IDS[_skin_select.selected]
	avatar.hair_id = AvatarDescriptor.HAIR_IDS[_hair_select.selected]
	avatar.outfit_id = AvatarDescriptor.OUTFIT_IDS[_outfit_select.selected]
	avatar.accessory_id = AvatarDescriptor.ACCESSORY_IDS[_accessory_select.selected]
	return avatar


func submit(display_name_fallback := "") -> void:
	submitted.emit(get_display_name(display_name_fallback), get_avatar())


func _build_controls() -> void:
	add_theme_constant_override("separation", 10)
	if show_name_field:
		name_edit = LineEdit.new()
		name_edit.placeholder_text = "Display name"
		name_edit.max_length = 24
		add_child(name_edit)
	if show_avatar_fields:
		_body_select = _option_row("Body", AvatarDescriptor.BODY_IDS)
		_skin_select = _option_row("Skin", AvatarDescriptor.SKIN_IDS)
		_hair_select = _option_row("Hair", AvatarDescriptor.HAIR_IDS)
		_outfit_select = _option_row("Outfit", AvatarDescriptor.OUTFIT_IDS)
		_accessory_select = _option_row("Accessory", AvatarDescriptor.ACCESSORY_IDS)
	if not submit_button_text.is_empty():
		var submit_button := Button.new()
		submit_button.text = submit_button_text
		submit_button.pressed.connect(func() -> void: submit())
		add_child(submit_button)


func _option_row(label_text: String, values: Array) -> OptionButton:
	var row := HBoxContainer.new()
	add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 110.0
	row.add_child(label)
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for value in values:
		option.add_item(pretty_id(value))
	row.add_child(option)
	return option


func _select(option: OptionButton, values: Array, value: StringName) -> void:
	if option != null:
		option.select(maxi(0, values.find(value)))


static func pretty_id(value: StringName) -> String:
	var parts := str(value).split("_", false)
	if parts.size() > 1:
		parts.remove_at(0)
	return " ".join(parts).capitalize()
