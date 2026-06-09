class_name Game
extends Node

@onready var player: PlayerDesktopRig = $Apartment/PlayerDesktopRig
@onready var apartment: Node = $Apartment
@onready var hud: HUD = $HUD


func _ready() -> void:
	var inventory := player.get_inventory()
	var wallet := player.get_wallet()
	var interaction_controller := player.get_interaction_controller()
	var look_controller := player.get_look_controller()

	hud.set_inventory(inventory)
	hud.set_wallet(wallet)
	hud.set_player_stats(_find_player_stats())
	interaction_controller.prompt_changed.connect(hud.set_interaction_prompt)
	interaction_controller.panel_data_changed.connect(hud.set_machine_panel_data)
	_connect_status_sources(apartment)
	look_controller.mouse_capture_changed.connect(_on_mouse_capture_changed)

	hud.set_interaction_prompt(interaction_controller.get_current_prompt())
	hud.set_machine_panel_data(interaction_controller.get_current_panel_data())
	hud.set_status("Click the game to capture the mouse. Escape releases it.")


func _on_mouse_capture_changed(is_captured: bool) -> void:
	if is_captured:
		hud.set_status("Mouse captured. Escape releases it.")
	else:
		hud.set_status("Mouse released. Click the game to capture it.")


func _connect_status_sources(node: Node) -> void:
	if node.has_signal("status_changed") and not node.is_connected("status_changed", hud.set_status):
		node.connect("status_changed", hud.set_status)
	for child in node.get_children():
		_connect_status_sources(child)


func _find_player_stats() -> Node:
	if player.has_method("get_player_stats"):
		var player_stats: Variant = player.call("get_player_stats")
		if player_stats is Node and _is_player_stats(player_stats):
			return player_stats
	return _find_player_stats_child(player)


func _find_player_stats_child(node: Node) -> Node:
	if _is_player_stats(node):
		return node
	for child: Node in node.get_children():
		var player_stats := _find_player_stats_child(child)
		if player_stats != null:
			return player_stats
	return null


func _is_player_stats(node: Node) -> bool:
	return (
		node.has_method("get_reputation")
		and node.has_method("set_reputation")
		and node.has_method("get_heat")
		and node.has_method("set_heat")
	)
