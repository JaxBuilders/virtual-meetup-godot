class_name RoomHUD
extends CanvasLayer

signal chat_submitted(message: String)
signal emote_selected(emote_id: StringName)
signal leave_requested
signal lock_changed(locked: bool)
signal profile_submitted(display_name: String, avatar: AvatarDescriptor)
signal player_block_changed(player_id: int, blocked: bool)
signal modal_visibility_changed(visible: bool)

var prompt_label: Label
var status_label: Label
var chat_log: RichTextLabel
var chat_entry: LineEdit
var room_menu: PanelContainer
var emote_panel: PanelContainer
var people_list: VBoxContainer
var code_label: Label
var lock_toggle: CheckButton
var _profile_name: LineEdit
var _body_select: OptionButton
var _skin_select: OptionButton
var _hair_select: OptionButton
var _outfit_select: OptionButton
var _accessory_select: OptionButton
var _participant_rows: Dictionary = {}


func _ready() -> void:
	_build_ui()


func set_prompt(value: String) -> void:
	prompt_label.text = value


func set_status(value: String) -> void:
	status_label.text = value


func set_room_code(value: String) -> void:
	code_label.text = "Room: %s" % value


func set_profile(profile: LocalProfile) -> void:
	_profile_name.text = profile.display_name
	_select(_body_select, AvatarDescriptor.BODY_IDS, profile.avatar.body_id)
	_select(_skin_select, AvatarDescriptor.SKIN_IDS, profile.avatar.skin_id)
	_select(_hair_select, AvatarDescriptor.HAIR_IDS, profile.avatar.hair_id)
	_select(_outfit_select, AvatarDescriptor.OUTFIT_IDS, profile.avatar.outfit_id)
	_select(_accessory_select, AvatarDescriptor.ACCESSORY_IDS, profile.avatar.accessory_id)


func add_chat(display_name: String, message: String) -> void:
	chat_log.append_text("[color=#7ee0d4]%s[/color]: %s\n" % [display_name, message])
	chat_log.scroll_to_line(maxi(0, chat_log.get_line_count() - 1))


func open_chat() -> void:
	chat_entry.show()
	chat_entry.grab_focus()
	modal_visibility_changed.emit(true)


func toggle_menu() -> void:
	room_menu.visible = not room_menu.visible
	if room_menu.visible:
		emote_panel.hide()
	modal_visibility_changed.emit(room_menu.visible)


func toggle_emotes() -> void:
	emote_panel.visible = not emote_panel.visible
	if emote_panel.visible:
		room_menu.hide()
	modal_visibility_changed.emit(emote_panel.visible)


func close_modals() -> bool:
	var was_open := room_menu.visible or emote_panel.visible or chat_entry.visible
	room_menu.hide()
	emote_panel.hide()
	chat_entry.hide()
	chat_entry.release_focus()
	modal_visibility_changed.emit(false)
	return was_open


func set_room_locked(value: bool) -> void:
	lock_toggle.set_pressed_no_signal(value)


func upsert_participant(snapshot: ParticipantSnapshot) -> void:
	remove_participant(snapshot.player_id)
	var row := HBoxContainer.new()
	row.name = "Participant%d" % snapshot.player_id
	var name_label := Label.new()
	name_label.text = "%s%s%s" % [snapshot.display_name, " (you)" if snapshot.is_local else "", " ★" if snapshot.is_master else ""]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	if not snapshot.is_local:
		var block := CheckButton.new()
		block.text = "Block"
		block.button_pressed = snapshot.is_blocked
		block.toggled.connect(func(value: bool) -> void: player_block_changed.emit(snapshot.player_id, value))
		row.add_child(block)
	people_list.add_child(row)
	_participant_rows[snapshot.player_id] = row


func remove_participant(player_id: int) -> void:
	var existing := _participant_rows.get(player_id) as Control
	if existing != null:
		existing.queue_free()
		_participant_rows.erase(player_id)


func _build_ui() -> void:
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.position = Vector2(632.0, 346.0)
	crosshair.add_theme_font_size_override("font_size", 20)
	add_child(crosshair)
	prompt_label = Label.new()
	prompt_label.position = Vector2(440.0, 540.0)
	prompt_label.size = Vector2(400.0, 30.0)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(prompt_label)
	status_label = Label.new()
	status_label.position = Vector2(24.0, 20.0)
	status_label.size = Vector2(500.0, 30.0)
	status_label.add_theme_color_override("font_color", Color("d9e7ef"))
	add_child(status_label)
	chat_log = RichTextLabel.new()
	chat_log.bbcode_enabled = true
	chat_log.position = Vector2(24.0, 445.0)
	chat_log.size = Vector2(390.0, 180.0)
	chat_log.fit_content = false
	chat_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(chat_log)
	chat_entry = LineEdit.new()
	chat_entry.position = Vector2(24.0, 632.0)
	chat_entry.size = Vector2(390.0, 38.0)
	chat_entry.placeholder_text = "Room chat (ephemeral)"
	chat_entry.max_length = SessionTransport.CHAT_MAX_LENGTH
	chat_entry.text_submitted.connect(_submit_chat)
	chat_entry.focus_exited.connect(_on_chat_focus_exited)
	chat_entry.hide()
	add_child(chat_entry)
	emote_panel = _build_emote_panel()
	room_menu = _build_room_menu()


func _build_emote_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = Vector2(475.0, 225.0)
	panel.size = Vector2(330.0, 270.0)
	panel.hide()
	add_child(panel)
	var content := VBoxContainer.new()
	panel.add_child(content)
	var title := Label.new()
	title.text = "Emotes"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	for emote_id in SessionTransport.EMOTE_IDS:
		var button := Button.new()
		button.text = str(emote_id).capitalize()
		button.pressed.connect(func() -> void:
			emote_selected.emit(emote_id)
			close_modals()
		)
		content.add_child(button)
	return panel


func _build_room_menu() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = Vector2(290.0, 90.0)
	panel.size = Vector2(700.0, 540.0)
	panel.hide()
	add_child(panel)
	var root := VBoxContainer.new()
	panel.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	code_label = Label.new()
	code_label.text = "Room"
	code_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(code_label)
	var copy := Button.new()
	copy.text = "Copy code"
	copy.pressed.connect(func() -> void: DisplayServer.clipboard_set(code_label.text.trim_prefix("Room: ")))
	header.add_child(copy)
	var close := Button.new()
	close.text = "×"
	close.pressed.connect(close_modals)
	header.add_child(close)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(tabs)
	var people := VBoxContainer.new()
	people.name = "People"
	tabs.add_child(people)
	people_list = VBoxContainer.new()
	people_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	people.add_child(people_list)
	lock_toggle = CheckButton.new()
	lock_toggle.text = "Lock room to new guests"
	lock_toggle.toggled.connect(func(value: bool) -> void: lock_changed.emit(value))
	people.add_child(lock_toggle)
	var guidance := Label.new()
	guidance.text = "Blocking is local. For serious issues, copy the participant ID and leave the room."
	guidance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	people.add_child(guidance)
	var avatar := VBoxContainer.new()
	avatar.name = "Avatar"
	tabs.add_child(avatar)
	_profile_name = LineEdit.new()
	_profile_name.placeholder_text = "Display name"
	_profile_name.max_length = 24
	avatar.add_child(_profile_name)
	_body_select = _option(avatar, "Body", AvatarDescriptor.BODY_IDS)
	_skin_select = _option(avatar, "Skin", AvatarDescriptor.SKIN_IDS)
	_hair_select = _option(avatar, "Hair", AvatarDescriptor.HAIR_IDS)
	_outfit_select = _option(avatar, "Outfit", AvatarDescriptor.OUTFIT_IDS)
	_accessory_select = _option(avatar, "Accessory", AvatarDescriptor.ACCESSORY_IDS)
	var apply := Button.new()
	apply.text = "Apply avatar"
	apply.pressed.connect(_submit_profile)
	avatar.add_child(apply)
	var settings := VBoxContainer.new()
	settings.name = "Settings"
	tabs.add_child(settings)
	_slider(settings, "Mouse sensitivity", SettingsStore.mouse_sensitivity, 0.0005, 0.01, 0.0005, SettingsStore.set_mouse_sensitivity)
	_slider(settings, "Field of view", SettingsStore.field_of_view, 60.0, 110.0, 1.0, SettingsStore.set_field_of_view)
	_slider(settings, "Master volume", SettingsStore.master_volume, 0.0, 1.0, 0.05, SettingsStore.set_master_volume)
	_slider(settings, "Text scale", SettingsStore.text_scale, 0.8, 1.5, 0.05, SettingsStore.set_text_scale)
	var reduced_motion := CheckButton.new()
	reduced_motion.text = "Reduce decorative motion"
	reduced_motion.button_pressed = SettingsStore.reduced_motion
	reduced_motion.toggled.connect(SettingsStore.set_reduced_motion)
	settings.add_child(reduced_motion)
	var voice := Label.new()
	voice.text = "Voice: coming later (no microphone is accessed)"
	settings.add_child(voice)
	var leave := Button.new()
	leave.text = "Leave Room"
	leave.pressed.connect(func() -> void: leave_requested.emit())
	root.add_child(leave)
	return panel


func _submit_chat(value: String) -> void:
	if not value.strip_edges().is_empty():
		chat_submitted.emit(value)
	chat_entry.clear()
	chat_entry.hide()
	chat_entry.release_focus()
	modal_visibility_changed.emit(false)


func _on_chat_focus_exited() -> void:
	if chat_entry.visible:
		chat_entry.hide()
		modal_visibility_changed.emit(false)


func _submit_profile() -> void:
	var avatar := AvatarDescriptor.new()
	avatar.body_id = AvatarDescriptor.BODY_IDS[_body_select.selected]
	avatar.skin_id = AvatarDescriptor.SKIN_IDS[_skin_select.selected]
	avatar.hair_id = AvatarDescriptor.HAIR_IDS[_hair_select.selected]
	avatar.outfit_id = AvatarDescriptor.OUTFIT_IDS[_outfit_select.selected]
	avatar.accessory_id = AvatarDescriptor.ACCESSORY_IDS[_accessory_select.selected]
	profile_submitted.emit(_profile_name.text, avatar)


func _option(parent: VBoxContainer, label_text: String, values: Array) -> OptionButton:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 110.0
	row.add_child(label)
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for value in values:
		option.add_item(str(value).trim_prefix(str(value).get_slice("_", 0) + "_").capitalize())
	row.add_child(option)
	return option


func _slider(parent: VBoxContainer, label_text: String, value: float, minimum: float, maximum: float, step: float, setter: Callable) -> void:
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


func _select(option: OptionButton, values: Array, value: StringName) -> void:
	option.select(maxi(0, values.find(value)))
