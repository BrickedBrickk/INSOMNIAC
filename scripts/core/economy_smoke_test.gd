extends SceneTree

var _failures: PackedStringArray = []
var _sell_statuses: PackedStringArray = []
var _stash_statuses: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main := main_scene.instantiate()
	root.add_child(main)

	await physics_frame
	await physics_frame

	var player: PlayerDesktopRig = main.get_node("Apartment/PlayerDesktopRig")
	var sell_terminal: SellTerminal = main.get_node("Apartment/SellTerminal")
	var stash_box: StashBox = main.get_node("Apartment/StashBox")
	var hud: HUD = main.get_node("HUD")
	var inventory := player.get_inventory()
	var wallet := player.get_wallet()

	sell_terminal.status_changed.connect(_sell_statuses.append)
	stash_box.status_changed.connect(_stash_statuses.append)

	_expect(wallet.get_money() == 0, "Wallet should start at $0.")
	_expect(hud.money_label.text == "Money: $0", "Wallet HUD should start at $0.")
	_expect(sell_terminal.get_interaction_prompt() == "Press E: Sell Lucids", "Sell prompt should be correct.")
	_expect(stash_box.get_interaction_prompt() == "Press E: Deposit Lucids", "Stash prompt should be correct.")

	inventory.add_item("beach_loop", "Beach Loop", 2)
	inventory.add_item("fast_life", "Fast Life", 1)
	var starting_blank_amount := inventory.get_amount("blank_cartridge")

	var sell_panel_data := sell_terminal.get_interaction_panel_data(player)
	hud.set_machine_panel_data(sell_panel_data)
	var sell_panel_text := _get_panel_text(hud.machine_panel)
	_expect(hud.machine_panel.visible, "Sell panel should be visible.")
	_expect(hud.machine_panel.machine_name_label.text == "Sell Terminal", "Sell panel should show its machine name.")
	_expect(sell_panel_text.contains("Beach Loop: 2 x $25 = $50"), "Sell panel should show Beach Loop value.")
	_expect(sell_panel_text.contains("Fast Life: 1 x $65 = $65"), "Sell panel should show Fast Life value.")
	_expect(sell_panel_text.contains("Total: $115"), "Sell panel should show the total sale value.")
	_expect(hud.machine_panel.controls_label.text == "E = Sell Lucids", "Sell panel should show its control.")

	sell_terminal.interact(player)
	_expect(inventory.get_amount("beach_loop") == 0, "Selling should remove all Beach Loops.")
	_expect(inventory.get_amount("fast_life") == 0, "Selling should remove all Fast Lifes.")
	_expect(inventory.get_amount("blank_cartridge") == starting_blank_amount, "Selling should leave ingredients untouched.")
	_expect(wallet.get_money() == 115, "Selling should add the correct total to the wallet.")
	_expect(hud.money_label.text == "Money: $115", "Wallet HUD should update after selling.")
	_expect(_sell_statuses.has("Sold Lucids for $115"), "Selling should emit a clean status message.")
	_expect(hud.status_message.text == "Sold Lucids for $115", "HUD should show the sell status.")
	_expect(wallet.spend_money(15), "Wallet should allow a test purchase after selling.")
	_expect(hud.money_label.text == "Money: $100", "Wallet HUD should update after spending money.")
	wallet.add_money(15)
	_expect(hud.money_label.text == "Money: $115", "Wallet HUD should update after money is restored.")

	hud.set_machine_panel_data(sell_terminal.get_interaction_panel_data(player))
	sell_panel_text = _get_panel_text(hud.machine_panel)
	_expect(sell_panel_text.contains("No Lucids to sell."), "Sell panel should refresh after selling.")

	inventory.add_item("penthouse", "Penthouse", 2)
	hud.set_machine_panel_data(stash_box.get_interaction_panel_data(player))
	var stash_panel_text := _get_panel_text(hud.machine_panel)
	_expect(hud.machine_panel.machine_name_label.text == "Stash Box", "Stash panel should show its machine name.")
	_expect(stash_panel_text.contains("Deposit from inventory:"), "Stash panel should show deposit section.")
	_expect(stash_panel_text.contains("Penthouse: 2"), "Stash panel should show depositable Penthouse.")
	_expect(stash_panel_text.contains("Stash contents:\n(empty)"), "Stash panel should show empty contents.")
	_expect(hud.machine_panel.controls_label.text == "E = Deposit Lucids", "Stash panel should show its control.")

	stash_box.interact(player)
	_expect(inventory.get_amount("penthouse") == 0, "Depositing should remove all Penthouses.")
	_expect(inventory.get_amount("blank_cartridge") == starting_blank_amount, "Depositing should leave ingredients untouched.")
	_expect(stash_box.get_contents().get("penthouse", 0) == 2, "Stash should contain deposited Penthouses.")
	_expect(_stash_statuses.has("Deposited Lucids into stash"), "Depositing should emit a clean status message.")
	_expect(hud.status_message.text == "Deposited Lucids into stash", "HUD should show the deposit status.")

	hud.set_machine_panel_data(stash_box.get_interaction_panel_data(player))
	stash_panel_text = _get_panel_text(hud.machine_panel)
	_expect(stash_panel_text.contains("No Lucids to deposit."), "Stash panel should refresh after depositing.")
	_expect(stash_panel_text.contains("Penthouse: 2"), "Stash panel should show deposited contents.")

	var money_before_empty_sale := wallet.get_money()
	sell_terminal.interact(player)
	_expect(wallet.get_money() == money_before_empty_sale, "An empty sale should not change money.")
	_expect(_sell_statuses.has("No Lucids to sell"), "Empty selling should emit a clean status message.")
	_expect(hud.status_message.text == "No Lucids to sell", "HUD should show the empty sell status.")

	stash_box.interact(player)
	_expect(_stash_statuses.has("No Lucids to deposit"), "Empty deposit should emit a clean status message.")
	_expect(hud.status_message.text == "No Lucids to deposit", "HUD should show the empty deposit status.")

	hud.set_machine_panel_data({})
	_expect(not hud.machine_panel.visible, "Empty panel data should hide the machine panel.")

	if _failures.is_empty():
		print("ECONOMY_SMOKE_TEST: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("ECONOMY_SMOKE_TEST: FAIL")
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _get_panel_text(panel: MachinePanel) -> String:
	var lines: PackedStringArray = [panel.machine_name_label.text]
	for child in panel.generic_sections.get_children():
		if child is Label:
			lines.append(child.text)
	lines.append(panel.controls_label.text)
	return "\n".join(lines)
