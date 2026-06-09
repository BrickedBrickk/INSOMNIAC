class_name Interactable
extends StaticBody3D

@export var prompt_name: String = "Interactable"


func interact(_player: Node) -> void:
	pass


func get_interaction_prompt() -> String:
	return "Press E: %s" % prompt_name
