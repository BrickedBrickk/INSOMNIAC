extends SceneTree

var _failures: PackedStringArray = []
var _events: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	_expect(main_scene != null, "Main scene should load.")
	if main_scene == null:
		_finish()
		return

	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame

	var player := main.get_node_or_null("Apartment/PlayerDesktopRig") as PlayerDesktopRig
	var manager := main.get_node_or_null("HeatEventManager")
	var hud := main.get_node_or_null("HUD") as HUD
	_expect(player != null, "Main should contain PlayerDesktopRig.")
	_expect(manager != null, "Main should contain HeatEventManager.")
	_expect(hud != null, "Main should contain HUD.")
	if player == null or manager == null or hud == null:
		_finish()
		return

	var player_stats := player.get_player_stats()
	_expect(player_stats != null, "Main flow should find PlayerStats.")
	_expect(main._find_player_stats() == player_stats, "Game should resolve the player's PlayerStats.")
	if player_stats == null:
		_finish()
		return

	manager.connect("heat_event_triggered", _record_event)
	_expect(hud.money_label.text == "Money: $0", "Money HUD should keep its starting value.")
	_expect(hud.reputation_label.text == "Reputation: 0", "Reputation HUD should keep its starting value.")
	_expect(hud.heat_label.text == "Heat: 0% - Quiet", "Heat HUD should keep its starting value.")

	player_stats.set_heat(20)
	_expect(_events.size() == 1, "Raising heat to 20 should emit exactly one event.")
	await process_frame
	_expect(hud.status_message.text == "DPI chatter is picking up.", "Heat 20 should reach HUD status.")
	_expect(hud.heat_label.text == "Heat: 20% - Noticed", "Heat HUD should update at 20.")

	player_stats.set_heat(20)
	_expect(_events.size() == 1, "Re-setting heat 20 should not spam events.")
	await process_frame
	_expect(hud.status_message.text == "DPI chatter is picking up.", "Re-setting heat should not replace HUD status.")

	player_stats.set_heat(40)
	_expect(_events.size() == 2, "Raising heat to 40 should emit the next event.")
	await process_frame
	_expect(
		hud.status_message.text == "DPI scanners have been seen nearby.",
		"Heat 40 should reach HUD status."
	)
	_expect(hud.heat_label.text == "Heat: 40% - Watched", "Heat HUD should update at 40.")
	_expect(hud.money_label.text == "Money: $0", "Heat events should not alter the money HUD.")
	_expect(hud.reputation_label.text == "Reputation: 0", "Heat events should not alter the reputation HUD.")

	_events.clear()
	manager.call("reset_triggered_events")
	player_stats.set_heat(12)
	var board := main.get_node("Apartment/CustomerOrderBoard") as CustomerOrderBoard
	var inventory := player.get_inventory()
	inventory.add_item("beach_loop", "Beach Loop", 1)
	inventory.add_item("fast_life", "Fast Life", 1)
	inventory.add_item("penthouse", "Penthouse", 1)
	board.interact(player)
	board.interact(player)
	board.interact(player)
	_expect(player_stats.get_heat() == 20, "Fulfilling the current orders from heat 12 should cross heat 20.")
	_expect(_events.size() == 1, "Order fulfillment crossing heat 20 should emit one event.")
	await process_frame
	_expect(
		hud.status_message.text == "DPI chatter is picking up.",
		"The DPI warning should remain visible after the fulfillment status."
	)

	_finish()


func _record_event(event_name: String, message: String, heat: int) -> void:
	_events.append({
		"name": event_name,
		"message": message,
		"heat": heat,
	})


func _finish() -> void:
	if _failures.is_empty():
		print("HEAT_EVENTS_INTEGRATION_SMOKE_TEST: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("HEAT_EVENTS_INTEGRATION_SMOKE_TEST: FAIL")
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
