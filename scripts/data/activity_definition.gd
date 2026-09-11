class_name ActivityDefinition
extends Resource

@export var activity_id: StringName
@export var display_name: String
@export var scene: PackedScene
@export_range(1, 16, 1) var maximum_players: int = 16
@export var spawn_anchors: PackedVector3Array
@export var capability_ids: PackedStringArray
