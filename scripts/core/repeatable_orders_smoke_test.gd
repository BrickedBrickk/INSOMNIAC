extends SceneTree

const SAVE_MANAGER_SCRIPT := preload("res://scripts/save/save_manager.gd")
const REFRESH_ORDERS: StringName = &"refresh_orders"

var _failures: PackedStringArray = []
var _statuses: PackedStringArray = []


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

	var player := main.get_node("Apartment/PlayerDesktopRig") as PlayerDesktopRig
	var board := main.get_node("Apartment/CustomerOrderBoard") as CustomerOrderBoard
	var interaction := player.get_interaction_controller() as InteractionController
	var inventory := player.get_inventory()
	var wallet := player.get_wallet()
	var stats := player.get_player_stats()
	var hud := main.get_node("HUD") as HUD
	var save_manager = SAVE_MANAGER_SCRIPT.new()
	board.status_changed.connect(_statuses.append)

	_expect(InputMap.has_action(REFRESH_ORDERS), "The refresh_orders input action should exist.")
	_expect(board.get_completed_orders_for_save().is_empty(), "Orders should begin incomplete.")
	_expect(
		_get_panel_text(board.get_interaction_panel_data(player)).contains("No completed orders to refresh."),
		"The panel should show when no completed orders can be refreshed."
	)

	inventory.add_item("beach_loop", "Beach Loop", 1)
	board.interact(player)
	_expect(board.get_completed_orders_for_save().has("quiet_night"), "Quiet Night should become completed.")
	_expect(wallet.get_money() == 40, "Quiet Night should pay $40.")
	_expect(stats.get_reputation() == 2, "Quiet Night should award reputation once.")
	_expect(stats.get_heat() == 1, "Quiet Night should award heat once.")

	var save_data: Dictionary = save_manager.build_save_data(main)
	board.load_completed_orders_from_save([])
	_expect(board.get_completed_orders_for_save().is_empty(), "Test setup should clear completed orders.")
	_expect(save_manager.apply_save_data(main, save_data), "Loading completed order state should succeed.")
	_expect(
		board.get_completed_orders_for_save().has("quiet_night"),
		"Save/load should preserve completed order state."
	)

	board.set_selected_order_index(0)
	inventory.add_item("beach_loop", "Beach Loop", 1)
	var money_before_repeat := wallet.get_money()
	var reputation_before_repeat := stats.get_reputation()
	var heat_before_repeat := stats.get_heat()
	var items_before_repeat := inventory.get_amount("beach_loop")
	board.interact(player)
	_expect(wallet.get_money() == money_before_repeat, "A completed order should not pay twice before refresh.")
	_expect(stats.get_reputation() == reputation_before_repeat, "A completed order should not award reputation twice.")
	_expect(stats.get_heat() == heat_before_repeat, "A completed order should not award heat twice.")
	_expect(
		inventory.get_amount("beach_loop") == items_before_repeat,
		"A completed order should not remove items twice."
	)

	var completed_panel := board.get_interaction_panel_data(player)
	_expect(completed_panel.get("status_text") == "COMPLETED", "The panel should show completed status.")
	_expect(
		_get_panel_text(completed_panel).contains("F = Refresh Orders ($50)"),
		"The panel should show the refresh control."
	)
	_expect(
		_get_panel_text(completed_panel).contains("Refresh available."),
		"The panel should show when refresh is available."
	)

	wallet.set_money(100)
	var inventory_before_refresh := inventory.get_all_items()
	player.position = Vector3(-3.75, 0.9, 2.5)
	interaction.force_raycast_update()
	await physics_frame
	_expect(interaction.get_collider() == board, "The interaction ray should reach the order board.")
	_send_action(interaction, REFRESH_ORDERS)
	_expect(wallet.get_money() == 50, "Refreshing through F should cost $50.")
	_expect(board.get_completed_orders_for_save().is_empty(), "Refreshing should clear completed orders.")
	_expect(inventory.get_all_items() == inventory_before_refresh, "Refreshing should not change inventory.")
	_expect(stats.get_reputation() == reputation_before_repeat, "Refreshing should not change reputation.")
	_expect(stats.get_heat() == heat_before_repeat, "Refreshing should not change heat.")
	_expect(_statuses.has("Orders refreshed."), "Refreshing should emit the expected status.")

	board.set_selected_order_index(0)
	board.interact(player)
	_expect(board.get_completed_orders_for_save().has("quiet_night"), "Quiet Night should complete again after refresh.")
	_expect(wallet.get_money() == 90, "Fulfilling Quiet Night after refresh should pay again.")
	_expect(stats.get_reputation() == reputation_before_repeat + 2, "Quiet Night should award reputation after refresh.")
	_expect(stats.get_heat() == heat_before_repeat + 1, "Quiet Night should award heat after refresh.")

	wallet.set_money(49)
	_expect(not board.refresh_orders(player), "Refresh should fail without enough money.")
	_expect(wallet.get_money() == 49, "Failed refresh should not spend money.")
	_expect(board.get_completed_orders_for_save().has("quiet_night"), "Failed refresh should preserve completions.")
	_expect(
		_statuses.has("Not enough money to refresh orders."),
		"Insufficient funds should emit the expected status."
	)

	board.load_completed_orders_from_save([])
	wallet.set_money(100)
	_expect(not board.refresh_orders(player), "Refresh should fail when no orders are completed.")
	_expect(wallet.get_money() == 100, "Refreshing with no completions should not spend money.")
	_expect(
		_statuses.has("No completed orders to refresh."),
		"No completed orders should emit the expected status."
	)

	wallet.set_money(1000)
	for repeat_index: int in 18:
		inventory.add_item("beach_loop", "Beach Loop", 1)
		board.set_selected_order_index(0)
		board.interact(player)
		if repeat_index < 17:
			_expect(board.refresh_orders(player), "Repeated refreshes should succeed with enough money.")
	_expect(stats.get_heat() == 20, "Repeated Quiet Night orders should be able to cross Heat 20.")
	await process_frame
	_expect(
		hud.status_message.text == "DPI chatter is picking up.",
		"Crossing Heat 20 through repeatable orders should show the DPI warning."
	)

	_finish()


func _send_action(interaction: InteractionController, action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	interaction._unhandled_input(event)


func _get_panel_text(panel_data: Dictionary) -> String:
	var lines: PackedStringArray = [str(panel_data.get("machine_name", ""))]
	for section: Dictionary in panel_data.get("sections", []):
		lines.append(str(section.get("title", "")))
		for line in section.get("lines", []):
			lines.append(str(line))
	lines.append(str(panel_data.get("status_text", "")))
	lines.append(str(panel_data.get("controls_text", "")))
	return "\n".join(lines)


func _finish() -> void:
	if _failures.is_empty():
		print("REPEATABLE_ORDERS_SMOKE_TEST: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("REPEATABLE_ORDERS_SMOKE_TEST: FAIL")
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
