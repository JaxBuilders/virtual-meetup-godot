class_name PlayerCommand
extends RefCounted

var movement: Vector2 = Vector2.ZERO
var look: Vector2 = Vector2.ZERO
var camera_zoom: float = 0.0
var jump_pressed: bool = false
var sprint_held: bool = false
var interact_pressed: bool = false
var primary_pressed: bool = false
var view_pressed: bool = false
var chat_pressed: bool = false
var emotes_pressed: bool = false
var menu_pressed: bool = false
var cancel_pressed: bool = false
