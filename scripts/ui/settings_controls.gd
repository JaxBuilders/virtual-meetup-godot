class_name SettingsControls
extends VBoxContainer

var voice_note: String = "Voice: coming later (no microphone is accessed)"


func configure(value_voice_note: String) -> void:
	voice_note = value_voice_note


func _ready() -> void:
	_build_controls()


func _build_controls() -> void:
	add_theme_constant_override("separation", 8)
	_add_slider("Mouse sensitivity", SettingsStore.mouse_sensitivity, 0.0005, 0.01, 0.0005, SettingsStore.set_mouse_sensitivity)
	_add_slider("Field of view", SettingsStore.field_of_view, 60.0, 110.0, 1.0, SettingsStore.set_field_of_view)
	_add_slider("Master volume", SettingsStore.master_volume, 0.0, 1.0, 0.05, SettingsStore.set_master_volume)
	_add_slider("Text scale", SettingsStore.text_scale, 0.8, 1.5, 0.05, SettingsStore.set_text_scale)
	var reduced_motion := CheckButton.new()
	reduced_motion.text = "Reduce decorative motion"
	reduced_motion.button_pressed = SettingsStore.reduced_motion
	reduced_motion.toggled.connect(SettingsStore.set_reduced_motion)
	add_child(reduced_motion)
	var voice := Label.new()
	voice.text = voice_note
	voice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(voice)


func _add_slider(label_text: String, value: float, minimum: float, maximum: float, step: float, setter: Callable) -> void:
	var label := Label.new()
	label.text = label_text
	add_child(label)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = value
	slider.value_changed.connect(func(new_value: float) -> void: setter.call(new_value))
	add_child(slider)
