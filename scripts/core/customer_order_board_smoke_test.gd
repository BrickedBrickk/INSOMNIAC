extends SceneTree

var _failures: PackedStringArray = []
var _statuses: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var board_scene: PackedScene = load("res://scenes/world/CustomerOrderBoard.tscn")
	_expect(board_scene != null, "CustomerOrderBoard scene should load.")
	if board_scene == null:
		_finish()
		return

	var board := board_scene.instantiate() as CustomerOrderBoard
	var player_scene: PackedScene = load("res://scenes/player/PlayerDesktopRig.tscn")
	var player := player_scene.instantiate() as PlayerDesktopRig
	root.add_child(board)
	root.add_child(player)

	await process_frame

	var inventory := player.get_inventory()
	var wallet := player.get_wallet()
	board.status_changed.connect(_statuses.append)

	_expect(board != null, "CustomerOrderBoard should instantiate.")
	_expect(board.orders.size() == 3, "CustomerOrderBoard should have three orders.")
	_expect(board.get_interaction_prompt() == "Press E: Fulfill Order", "Board prompt should be correct.")
	_expect(board.get_selected_order().id == "quiet_night", "Quiet Night should be selected first.")
	_expect(
		board.orders[0].customer_name == "Milo"
		and board.orders[0].requested_item_id == "beach_loop"
		and board.orders[0].requested_amount == 1
		and board.orders[0].payout == 40
		and board.orders[0].reputation_gain == 2
		and board.orders[0].heat_gain == 1,
		"Quiet Night data should be correct."
	)
	_expect(
		board.orders[1].id == "fast_fix"
		and board.orders[1].customer_name == "Vex"
		and board.orders[1].requested_item_id == "fast_life"
		and board.orders[1].payout == 90
		and board.orders[1].reputation_gain == 3
		and board.orders[1].heat_gain == 4,
		"Fast Fix data should be correct."
	)
	_expect(
		board.orders[2].id == "penthouse_trial"
		and board.orders[2].customer_name == "June"
		and board.orders[2].requested_item_id == "penthouse"
		and board.orders[2].payout == 130
		and board.orders[2].reputation_gain == 5
		and board.orders[2].heat_gain == 3,
		"Penthouse Trial data should be correct."
	)

	board.secondary_interact(player)
	_expect(board.get_selected_order().id == "fast_fix", "Cycling should select Fast Fix.")
	board.secondary_interact(player)
	board.secondary_interact(player)
	_expect(board.get_selected_order().id == "quiet_night", "Cycling should wrap to Quiet Night.")

	var starting_money := wallet.get_money()
	var starting_blank_amount := inventory.get_amount("blank_cartridge")
	board.interact(player)
	_expect(inventory.get_amount("beach_loop") == 0, "Failed fulfillment should not remove an item.")
	_expect(wallet.get_money() == starting_money, "Failed fulfillment should not add money.")
	_expect(board.get_selected_order().id == "quiet_night", "Failed fulfillment should not rotate orders.")
	_expect(_statuses.has("Missing Beach Loop: 0 / 1"), "Failed fulfillment should emit the missing requirement.")

	var missing_panel := board.get_interaction_panel_data(player)
	_expect(missing_panel.get("machine_name") == "Customer Orders", "Panel data should identify Customer Orders.")
	_expect(missing_panel.get("status_text") == "Missing requested Lucid", "Panel should show missing state.")
	_expect(_get_panel_text(missing_panel).contains("Owned / Required: 0 / 1"), "Panel should show owned and required amounts.")
	_expect(_get_panel_text(missing_panel).contains("E = Fulfill Order\nR = Switch Order"), "Panel should show controls.")

	inventory.add_item("beach_loop", "Beach Loop", 1)
	var ready_panel := board.get_interaction_panel_data(player)
	_expect(ready_panel.get("status_text") == "Ready to fulfill", "Panel should show ready state.")

	board.interact(player)
	_expect(inventory.get_amount("beach_loop") == 0, "Successful fulfillment should remove the requested Lucid.")
	_expect(wallet.get_money() == starting_money + 40, "Successful fulfillment should add the payout.")
	_expect(inventory.get_amount("blank_cartridge") == starting_blank_amount, "Fulfillment should leave non-requested ingredients untouched.")
	_expect(board.get_selected_order().id == "fast_fix", "Successful fulfillment should rotate to the next order.")
	_expect(_statuses.has("Fulfilled Quiet Night for $40"), "Successful fulfillment should emit a clean status.")

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("CUSTOMER_ORDER_BOARD_SMOKE_TEST: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("CUSTOMER_ORDER_BOARD_SMOKE_TEST: FAIL")
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _get_panel_text(panel_data: Dictionary) -> String:
	var lines: PackedStringArray = [str(panel_data.get("machine_name", ""))]
	for section: Dictionary in panel_data.get("sections", []):
		lines.append(str(section.get("title", "")))
		for line in section.get("lines", []):
			lines.append(str(line))
	lines.append(str(panel_data.get("status_text", "")))
	lines.append(str(panel_data.get("controls_text", "")))
	return "\n".join(lines)
