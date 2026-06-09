extends SceneTree

const SAVE_MANAGER_SCRIPT := preload("res://scripts/save/save_manager.gd")

var _failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var test_root := Node.new()
	test_root.name = "CustomerOrderSaveTest"
	root.add_child(test_root)

	var board_scene: PackedScene = load("res://scenes/world/CustomerOrderBoard.tscn")
	var player_scene: PackedScene = load("res://scenes/player/PlayerDesktopRig.tscn")
	_expect(board_scene != null, "CustomerOrderBoard scene should load.")
	_expect(player_scene != null, "Player scene should load.")
	if board_scene == null or player_scene == null:
		_finish(null)
		return

	var board := board_scene.instantiate() as CustomerOrderBoard
	var player := player_scene.instantiate() as PlayerDesktopRig
	test_root.add_child(board)
	test_root.add_child(player)

	await process_frame

	var save_manager = SAVE_MANAGER_SCRIPT.new()
	var inventory := player.get_inventory()
	var wallet := player.get_wallet()
	_expect(save_manager.delete_save(), "Deleting an old test save should succeed.")
	_expect(board.is_in_group("customer_order_boards"), "CustomerOrderBoard should join its save group.")

	wallet.set_money(100)
	inventory.add_item("beach_loop", "Beach Loop", 1)
	board.interact(player)
	_expect(board.get_completed_orders_for_save().has("quiet_night"), "Quiet Night should be completed.")
	_expect(wallet.get_money() == 140, "Quiet Night should pay out once.")
	_expect(board.get_selected_order_index() == 1, "Fulfillment should select the next order.")

	var save_data := save_manager.build_save_data(test_root)
	var board_entries: Array = save_data.get("customer_order_boards", [])
	_expect(board_entries.size() == 1, "Save data should include one CustomerOrderBoard.")
	if board_entries.size() == 1:
		_expect(board_entries[0].get("selected_order_index") == 1, "Save data should include the selected order.")
		_expect(
			board_entries[0].get("completed_orders", []).has("quiet_night"),
			"Save data should include completed order ids."
		)

	_expect(save_manager.save_game(test_root), "Saving customer order state should succeed.")

	board.set_selected_order_index(2)
	board.load_completed_orders_from_save([])
	_expect(board.get_completed_orders_for_save().is_empty(), "Test setup should clear completed orders.")

	_expect(save_manager.load_game(test_root), "Loading customer order state should succeed.")
	_expect(board.get_selected_order_index() == 1, "Loading should restore the selected order.")
	_expect(board.get_completed_orders_for_save().has("quiet_night"), "Loading should restore Quiet Night completion.")

	board.set_selected_order_index(0)
	inventory.add_item("beach_loop", "Beach Loop", 1)
	var money_before_repeat := wallet.get_money()
	var item_count_before_repeat := inventory.get_amount("beach_loop")
	board.interact(player)
	_expect(wallet.get_money() == money_before_repeat, "A completed order should not pay out again.")
	_expect(
		inventory.get_amount("beach_loop") == item_count_before_repeat,
		"A completed order should not remove its requested item again."
	)
	_expect(
		board.get_interaction_panel_data(player).get("status_text") == "COMPLETED",
		"A completed order should report COMPLETED in panel data."
	)

	board.load_order_state_from_save({
		"selected_order_index": 999,
		"completed_orders": ["quiet_night", "removed_order_id"],
	})
	_expect(board.get_selected_order_index() == board.orders.size() - 1, "Invalid saved indexes should clamp safely.")
	_expect(
		board.get_completed_orders_for_save() == ["quiet_night"],
		"Unknown completed order ids should be ignored."
	)

	var old_save_data := save_manager.build_save_data(test_root)
	old_save_data.erase("customer_order_boards")
	board.set_selected_order_index(0)
	var completion_before_old_save := board.get_completed_orders_for_save()
	_expect(
		save_manager.apply_save_data(test_root, old_save_data),
		"Old saves without customer order data should apply safely."
	)
	_expect(board.get_selected_order_index() == 0, "Missing customer order data should leave board selection unchanged.")
	_expect(
		board.get_completed_orders_for_save() == completion_before_old_save,
		"Missing customer order data should leave completions unchanged."
	)

	_finish(save_manager)


func _finish(save_manager) -> void:
	if save_manager != null:
		_expect(save_manager.delete_save(), "Deleting the customer order test save should succeed.")

	if _failures.is_empty():
		print("CUSTOMER_ORDER_SAVE_SMOKE_TEST: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("CUSTOMER_ORDER_SAVE_SMOKE_TEST: FAIL")
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
