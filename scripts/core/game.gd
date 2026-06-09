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
