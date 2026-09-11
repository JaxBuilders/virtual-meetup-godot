class_name Interactable
extends Node3D

@export var interaction_prompt: String = "Interact"


func get_interaction_prompt(_actor: Node) -> String:
	return interaction_prompt


func interact(_actor: Node) -> void:
	pass
