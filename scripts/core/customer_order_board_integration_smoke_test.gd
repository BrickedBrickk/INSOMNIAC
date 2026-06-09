extends SceneTree

var _failures: PackedStringArray = []


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
	var hud := main.get_node("HUD") as HUD
	_expect(player != null, "Player should exist in the apartment.")
	_expect(board != null, "CustomerOrderBoard should exist in the apartment.")
	_expect(hud != null, "HUD should exist in Main.")
	if player == null or board == null or hud == null:
		_finish()
		return

	var collision := board.get_node_or_null("CollisionShape3D") as CollisionShape3D
	_expect(collision != null and collision.shape != null and not collision.disabled, "Board collision should be enabled.")

	player.position = Vector3(-3.75, 0.9, 2.5)
	var interaction := player.get_interaction_controller()
	interaction.force_raycast_update()
	await physics_frame

	_expect(interaction.get_collider() == board, "The existing interaction ray should reach the board.")
	_expect(interaction.get_current_prompt() == "Press E: Fulfill Order", "The board prompt should appear.")
	_expect(interaction.get_current_panel_data().get("machine_name") == "Customer Orders", "The board should provide generic panel data.")
	_expect(hud.machine_panel.visible, "The MachinePanel should appear while looking at the board.")
	_expect(hud.machine_panel.machine_name_label.text == "Customer Orders", "The MachinePanel should identify Customer Orders.")
	_expect(hud.machine_panel.controls_label.text == "E = Fulfill Order\nR = Switch Order", "The MachinePanel should show board controls.")

	_send_action(interaction, InputActions.CYCLE_RECIPE)
	_expect(board.get_selected_order().id == "fast_fix", "R should cycle to Fast Fix through the interaction controller.")
	_send_action(interaction, InputActions.CYCLE_RECIPE)
	_expect(board.get_selected_order().id == "penthouse_trial", "R should cycle to Penthouse Trial through the interaction controller.")
	_send_action(interaction, InputActions.CYCLE_RECIPE)
	_expect(board.get_selected_order().id == "quiet_night", "R should wrap to Quiet Night through the interaction controller.")

	var inventory := player.get_inventory()
	var wallet := player.get_wallet()
	var starting_money := wallet.get_money()
	_send_action(interaction, InputActions.INTERACT)
	_expect(inventory.get_amount("beach_loop") == 0, "A missing-item order should not remove inventory.")
	_expect(wallet.get_money() == starting_money, "A missing-item order should not pay money.")
	_expect(board.get_selected_order().id == "quiet_night", "A failed order should remain selected.")

	inventory.add_item("beach_loop", "Beach Loop", 1)
	_send_action(interaction, InputActions.INTERACT)
	_expect(inventory.get_amount("beach_loop") == 0, "Fulfilling Quiet Night should remove Beach Loop.")
	_expect(wallet.get_money() == starting_money + 40, "Fulfilling Quiet Night should pay $40.")
	_expect(board.get_selected_order().id == "fast_fix", "A fulfilled order should advance to Fast Fix.")

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("CUSTOMER_ORDER_BOARD_INTEGRATION_SMOKE_TEST: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("CUSTOMER_ORDER_BOARD_INTEGRATION_SMOKE_TEST: FAIL")
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _send_action(interaction: InteractionController, action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	interaction._unhandled_input(event)
