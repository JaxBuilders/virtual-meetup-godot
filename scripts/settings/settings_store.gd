extends Node

signal settings_changed

const SCHEMA_VERSION := 1
const SETTINGS_PATH := "user://settings.cfg"

var mouse_sensitivity: float = 0.0025
var field_of_view: float = 80.0
var master_volume: float = 0.75
var reduced_motion: bool = false
var text_scale: float = 1.0


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		mouse_sensitivity = _number(config.get_value("controls", "mouse_sensitivity", mouse_sensitivity), mouse_sensitivity)
		field_of_view = _number(config.get_value("graphics", "field_of_view", field_of_view), field_of_view)
		master_volume = _number(config.get_value("audio", "master_volume", master_volume), master_volume)
		reduced_motion = bool(config.get_value("accessibility", "reduced_motion", reduced_motion))
		text_scale = _number(config.get_value("accessibility", "text_scale", text_scale), text_scale)
	_sanitize()
	_apply()
	save_settings()


func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = clampf(value, 0.0005, 0.01)
	_commit()


func set_field_of_view(value: float) -> void:
	field_of_view = clampf(value, 60.0, 110.0)
	_commit()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_commit()


func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	_commit()


func set_text_scale(value: float) -> void:
	text_scale = clampf(value, 0.8, 1.5)
	_commit()


func save_settings() -> Error:
	var config := ConfigFile.new()
	config.set_value("meta", "schema_version", SCHEMA_VERSION)
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("graphics", "field_of_view", field_of_view)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("accessibility", "reduced_motion", reduced_motion)
	config.set_value("accessibility", "text_scale", text_scale)
	return config.save(SETTINGS_PATH)


func _sanitize() -> void:
	mouse_sensitivity = clampf(mouse_sensitivity, 0.0005, 0.01)
	field_of_view = clampf(field_of_view, 60.0, 110.0)
	master_volume = clampf(master_volume, 0.0, 1.0)
	text_scale = clampf(text_scale, 0.8, 1.5)


func _apply() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(master_volume) if master_volume > 0.001 else -80.0)


func _commit() -> void:
	_sanitize()
	_apply()
	save_settings()
	settings_changed.emit()


func _number(value: Variant, fallback: float) -> float:
	return float(value) if value is float or value is int else fallback
