class_name HomeScreen
extends CanvasLayer

signal offline_requested
signal create_requested(region: StringName)
signal join_requested(code: String)
signal gallery_requested
signal profile_submitted(display_name: String, avatar: AvatarDescriptor)

var status_label: Label
var name_edit: LineEdit
var code_edit: LineEdit
var region_select: OptionButton
var customize_panel: PanelContainer
var settings_panel: PanelContainer
var _body_select: OptionButton
var _skin_select: OptionButton
var _hair_select: OptionButton
var _outfit_select: OptionButton
var _accessory_select: OptionButton


func _ready() -> void:
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		customize_panel.hide()
		settings_panel.hide()


func set_profile(profile: LocalProfile) -> void:
	name_edit.text = profile.display_name
	_select_value(_body_select, AvatarDescriptor.BODY_IDS, profile.avatar.body_id)
	_select_value(_skin_select, AvatarDescriptor.SKIN_IDS, profile.avatar.skin_id)
	_select_value(_hair_select, AvatarDescriptor.HAIR_IDS, profile.avatar.hair_id)
	_select_value(_outfit_select, AvatarDescriptor.OUTFIT_IDS, profile.avatar.outfit_id)
	_select_value(_accessory_select, AvatarDescriptor.ACCESSORY_IDS, profile.avatar.accessory_id)


func set_status(message: String, connecting := false) -> void:
	status_label.text = message
	status_label.modulate = Color("f3cb76") if connecting else Color("d9e7ef")


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("101827")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var accent := ColorRect.new()
	accent.color = Color("253a52")
	accent.position = Vector2(0.0, 470.0)
	accent.size = Vector2(1280.0, 250.0)
	backdrop.add_child(accent)
	var panel := PanelContainer.new()
	panel.position = Vector2(320.0, 95.0)
	panel.size = Vector2(640.0, 530.0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("1c2a3d")))
	backdrop.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	var title := Label.new()
	title.text = "VIRTUAL MEETUP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("7ee0d4"))
	content.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "A small clubhouse for large conversations."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color("a9bac8"))
	content.add_child(subtitle)
	name_edit = LineEdit.new()
	name_edit.placeholder_text = "Display name"
	name_edit.max_length = 24
	content.add_child(name_edit)
	var offline := Button.new()
	offline.text = "Play Offline"
	offline.pressed.connect(_on_offline_pressed)
	content.add_child(offline)
	var online_row := HBoxContainer.new()
	content.add_child(online_row)
	region_select = OptionButton.new()
	for region in ["US", "USW", "EU", "ASIA", "JP", "AU", "CAE", "SA", "IN", "KR", "TR", "ZA", "MENA"]:
		region_select.add_item(region)
	online_row.add_child(region_select)
	var create := Button.new()
	create.text = "Create Private Room"
	create.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create.pressed.connect(_on_create_pressed)
	online_row.add_child(create)
	var join_row := HBoxContainer.new()
	content.add_child(join_row)
	code_edit = LineEdit.new()
	code_edit.placeholder_text = "US-7K2M9Q4R"
	code_edit.max_length = 16
	code_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join_row.add_child(code_edit)
	var join := Button.new()
	join.text = "Join Code"
	join.pressed.connect(_on_join_pressed)
	join_row.add_child(join)
	var options_row := HBoxContainer.new()
	content.add_child(options_row)
	var customize := Button.new()
	customize.text = "Customize"
	customize.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	customize.pressed.connect(func() -> void: _show_panel(customize_panel))
	options_row.add_child(customize)
	var settings := Button.new()
	settings.text = "Settings"
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.pressed.connect(func() -> void: _show_panel(settings_panel))
	options_row.add_child(settings)
	var gallery := Button.new()
	gallery.text = "Avatar Gallery"
	gallery.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gallery.pressed.connect(func() -> void: gallery_requested.emit())
	options_row.add_child(gallery)
	status_label = Label.new()
	status_label.text = "Offline play is ready. Online rooms require a project App ID."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(status_label)
	customize_panel = _build_customize_panel(backdrop)
	settings_panel = _build_settings_panel(backdrop)


func _build_customize_panel(parent: Control) -> PanelContainer:
	var panel := _overlay_panel(parent, "Avatar")
	var content := panel.get_child(0) as VBoxContainer
	_body_select = _option_row(content, "Body", AvatarDescriptor.BODY_IDS)
	_skin_select = _option_row(content, "Skin", AvatarDescriptor.SKIN_IDS)
	_hair_select = _option_row(content, "Hair", AvatarDescriptor.HAIR_IDS)
	_outfit_select = _option_row(content, "Outfit", AvatarDescriptor.OUTFIT_IDS)
	_accessory_select = _option_row(content, "Accessory", AvatarDescriptor.ACCESSORY_IDS)
	var save := Button.new()
	save.text = "Save Profile"
	save.pressed.connect(_save_profile)
	content.add_child(save)
	return panel


func _build_settings_panel(parent: Control) -> PanelContainer:
	var panel := _overlay_panel(parent, "Settings")
	var content := panel.get_child(0) as VBoxContainer
	_add_slider(content, "Mouse sensitivity", SettingsStore.mouse_sensitivity, 0.0005, 0.01, 0.0005, SettingsStore.set_mouse_sensitivity)
	_add_slider(content, "Field of view", SettingsStore.field_of_view, 60.0, 110.0, 1.0, SettingsStore.set_field_of_view)
	_add_slider(content, "Master volume", SettingsStore.master_volume, 0.0, 1.0, 0.05, SettingsStore.set_master_volume)
	_add_slider(content, "Text scale", SettingsStore.text_scale, 0.8, 1.5, 0.05, SettingsStore.set_text_scale)
	var reduced_motion := CheckButton.new()
	reduced_motion.text = "Reduce decorative motion"
	reduced_motion.button_pressed = SettingsStore.reduced_motion
	reduced_motion.toggled.connect(SettingsStore.set_reduced_motion)
	content.add_child(reduced_motion)
	var voice := Label.new()
	voice.text = "Voice: coming in a later milestone"
	voice.add_theme_color_override("font_color", Color("8193a5"))
	content.add_child(voice)
	return panel


func _overlay_panel(parent: Control, title_text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = Vector2(390.0, 150.0)
	panel.size = Vector2(500.0, 420.0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("223247")))
	panel.visible = false
	parent.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "×"
	close.pressed.connect(func() -> void: panel.hide())
	header.add_child(close)
	return panel


func _option_row(parent: VBoxContainer, label_text: String, values: Array) -> OptionButton:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 110.0
	row.add_child(label)
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for value in values:
		option.add_item(_pretty_id(value))
	row.add_child(option)
	return option


func _add_slider(parent: VBoxContainer, label_text: String, value: float, minimum: float, maximum: float, step: float, setter: Callable) -> void:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = value
	slider.value_changed.connect(func(new_value: float) -> void: setter.call(new_value))
	parent.add_child(slider)


func _on_create_pressed() -> void:
	_submit_profile()
	create_requested.emit(StringName(region_select.get_item_text(region_select.selected).to_lower()))


func _save_profile() -> void:
	_submit_profile()
	customize_panel.hide()


func _submit_profile() -> void:
	var avatar := AvatarDescriptor.new()
	avatar.body_id = AvatarDescriptor.BODY_IDS[_body_select.selected]
	avatar.skin_id = AvatarDescriptor.SKIN_IDS[_skin_select.selected]
	avatar.hair_id = AvatarDescriptor.HAIR_IDS[_hair_select.selected]
	avatar.outfit_id = AvatarDescriptor.OUTFIT_IDS[_outfit_select.selected]
	avatar.accessory_id = AvatarDescriptor.ACCESSORY_IDS[_accessory_select.selected]
	profile_submitted.emit(name_edit.text, avatar)


func _on_offline_pressed() -> void:
	_submit_profile()
	offline_requested.emit()


func _on_join_pressed() -> void:
	_submit_profile()
	join_requested.emit(code_edit.text)


func _show_panel(panel: Control) -> void:
	customize_panel.visible = panel == customize_panel
	settings_panel.visible = panel == settings_panel


func _select_value(option: OptionButton, values: Array, selected: StringName) -> void:
	option.select(maxi(0, values.find(selected)))


func _pretty_id(value: StringName) -> String:
	var parts := str(value).split("_", false)
	if parts.size() > 1:
		parts.remove_at(0)
	return " ".join(parts).capitalize()


func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 20.0
	style.content_margin_bottom = 20.0
	return style
