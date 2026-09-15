class_name RoomHUD
extends CanvasLayer

const ProfileAvatarControlsScript := preload("res://scripts/ui/profile_avatar_controls.gd")
const SettingsControlsScript := preload("res://scripts/ui/settings_controls.gd")

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
var profile_controls
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
	if profile_controls != null:
		profile_controls.set_profile(profile)


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
		if existing.get_parent() != null:
			existing.get_parent().remove_child(existing)
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
	profile_controls = ProfileAvatarControlsScript.new()
	profile_controls.configure(true, true, "Apply avatar")
	profile_controls.submitted.connect(func(display_name: String, avatar_descriptor: AvatarDescriptor) -> void: profile_submitted.emit(display_name, avatar_descriptor))
	avatar.add_child(profile_controls)
	var settings := VBoxContainer.new()
	settings.name = "Settings"
	tabs.add_child(settings)
	var settings_controls = SettingsControlsScript.new()
	settings.add_child(settings_controls)
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
