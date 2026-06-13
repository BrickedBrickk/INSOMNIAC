class_name InteractionController
extends RayCast3D

signal prompt_changed(prompt: String)
signal panel_data_changed(panel_data: Dictionary)

const REFRESH_ORDERS: StringName = &"refresh_orders"

@export var player_path: NodePath = ^"../../.."

var _current_target: Object
var _current_prompt: String = ""
var _current_panel_data: Dictionary = {}


func _physics_process(_delta: float) -> void:
	force_raycast_update()
	var target := _get_valid_target()
	_current_target = target
	_refresh_target_data(target)


func _unhandled_input(event: InputEvent) -> void:
	var method_name := ""
	if event.is_action_pressed(InputActions.INTERACT):
		method_name = "interact"
	elif event.is_action_pressed(InputActions.CYCLE_RECIPE):
		method_name = "secondary_interact"
	elif event.is_action_pressed(REFRESH_ORDERS):
		method_name = "refresh_orders"
	else:
		return

	var target := _get_valid_target()
	if target == null or not target.has_method(method_name):
		return

	var player := _get_player()
	if player == null:
		push_warning("InteractionController could not find its player.")
		return

	target.call(method_name, player)
	_refresh_target_data(target)
	get_viewport().set_input_as_handled()


func get_current_prompt() -> String:
	return _current_prompt


func get_current_panel_data() -> Dictionary:
	return _current_panel_data


func _get_valid_target() -> Object:
	if not is_colliding():
		return null

	var collider := get_collider()
	if collider != null and collider.has_method("interact"):
		return collider
	return null


func _get_player() -> Node:
	var player := get_node_or_null(player_path)
	if player != null:
		return player

	var ancestor := get_parent()
	while ancestor != null:
		if ancestor.has_method("get_inventory"):
			return ancestor
		ancestor = ancestor.get_parent()
	return null


func _get_target_prompt(target: Object) -> String:
	if target == null:
		return ""
	if target.has_method("get_interaction_prompt"):
		return target.get_interaction_prompt()
	return "Press E: Interact"


func _get_target_panel_data(target: Object) -> Dictionary:
	if target == null or not target.has_method("get_interaction_panel_data"):
		return {}

	var player := _get_player()
	if player == null:
		return {}

	var panel_data = target.call("get_interaction_panel_data", player)
	return panel_data if panel_data is Dictionary else {}


func _refresh_target_data(target: Object) -> void:
	_set_prompt(_get_target_prompt(target))
	_set_panel_data(_get_target_panel_data(target))


func _set_prompt(prompt: String) -> void:
	if prompt == _current_prompt:
		return
	_current_prompt = prompt
	prompt_changed.emit(prompt)


func _set_panel_data(panel_data: Dictionary) -> void:
	if panel_data == _current_panel_data:
		return
	_current_panel_data = panel_data
	panel_data_changed.emit(panel_data)
