class_name HomeScreen
extends CanvasLayer

const ProfileAvatarControlsScript := preload("res://scripts/ui/profile_avatar_controls.gd")
const SettingsControlsScript := preload("res://scripts/ui/settings_controls.gd")

signal offline_requested
signal create_requested(region: StringName)
signal join_requested(code: String)
signal gallery_requested
signal profile_submitted(display_name: String, avatar: AvatarDescriptor)

var status_label: Label
var profile_controls
var avatar_controls
var code_edit: LineEdit
var region_select: OptionButton
var customize_panel: PanelContainer
var settings_panel: PanelContainer


func _ready() -> void:
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		customize_panel.hide()
		settings_panel.hide()


func set_profile(profile: LocalProfile) -> void:
	if profile_controls != null:
		profile_controls.set_profile(profile)
	if avatar_controls != null:
		avatar_controls.set_profile(profile)


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
	profile_controls = ProfileAvatarControlsScript.new()
	profile_controls.configure(true, false)
	content.add_child(profile_controls)
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
	avatar_controls = ProfileAvatarControlsScript.new()
	avatar_controls.configure(false, true, "Save Profile")
	avatar_controls.submitted.connect(_save_profile)
	content.add_child(avatar_controls)
	return panel


func _build_settings_panel(parent: Control) -> PanelContainer:
	var panel := _overlay_panel(parent, "Settings")
	var content := panel.get_child(0) as VBoxContainer
	var settings_controls = SettingsControlsScript.new()
	settings_controls.configure("Voice: coming in a later milestone")
	content.add_child(settings_controls)
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


func _on_create_pressed() -> void:
	_submit_profile()
	create_requested.emit(StringName(region_select.get_item_text(region_select.selected).to_lower()))


func _save_profile(_display_name: String, _avatar: AvatarDescriptor) -> void:
	_submit_profile()
	customize_panel.hide()


func _submit_profile() -> void:
	profile_submitted.emit(profile_controls.get_display_name(), avatar_controls.get_avatar())


func _on_offline_pressed() -> void:
	_submit_profile()
	offline_requested.emit()


func _on_join_pressed() -> void:
	_submit_profile()
	join_requested.emit(code_edit.text)


func _show_panel(panel: Control) -> void:
	customize_panel.visible = panel == customize_panel
	settings_panel.visible = panel == settings_panel


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
