extends SceneTree

var _failures: PackedStringArray = []
var _supply_statuses: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main := main_scene.instantiate()
	root.add_child(main)

	await physics_frame
	await physics_frame

	var player: PlayerDesktopRig = main.get_node("Apartment/PlayerDesktopRig")
	var supply_terminal: SupplyTerminal = main.get_node("Apartment/SupplyTerminal")
	var sell_terminal: SellTerminal = main.get_node("Apartment/SellTerminal")
	var stash_box: StashBox = main.get_node("Apartment/StashBox")
	var hud: HUD = main.get_node("HUD")
	var inventory := player.get_inventory()
	var wallet := player.get_wallet()

	supply_terminal.status_changed.connect(_supply_statuses.append)

	_expect(wallet.get_money() == 0, "Wallet should start at $0.")
	_expect(wallet.can_afford(0), "Wallet should be able to afford $0.")
	_expect(not wallet.can_afford(1), "Empty wallet should not afford $1.")
	_expect(not wallet.spend_money(1), "Wallet should reject unaffordable spending.")
	_expect(wallet.get_money() == 0, "Rejected spending should leave wallet unchanged.")

	_expect(supply_terminal.get_interaction_prompt() == "Press E: Buy Supplies", "Supply prompt should be correct.")
	_expect(supply_terminal.offers.size() == 7, "Supply Terminal should have seven offers.")
	_expect(supply_terminal.get_selected_offer().id == "blank_cartridge_pack", "Blank Cartridge Pack should be selected first.")
	_expect(supply_terminal.offers[0].amount == 3 and supply_terminal.offers[0].price == 30, "Blank Cartridge Pack data should be correct.")
	_expect(supply_terminal.offers[1].id == "beach_starter_pack" and supply_terminal.offers[1].price == 20, "Beach Starter Pack data should be correct.")
	_expect(supply_terminal.offers[2].id == "calm_layer_pack" and supply_terminal.offers[2].price == 20, "Calm Layer Pack data should be correct.")
	_expect(supply_terminal.offers[3].id == "speed_fragment_offer" and supply_terminal.offers[3].price == 30, "Speed Fragment data should be correct.")
	_expect(supply_terminal.offers[4].id == "hype_layer_offer" and supply_terminal.offers[4].price == 30, "Hype Layer data should be correct.")
	_expect(supply_terminal.offers[5].id == "luxury_fragment_offer" and supply_terminal.offers[5].price == 45, "Luxury Fragment data should be correct.")
	_expect(supply_terminal.offers[6].id == "premium_layer_offer" and supply_terminal.offers[6].price == 45, "Premium Layer data should be correct.")

	var starting_blank_amount := inventory.get_amount("blank_cartridge")
	wallet.add_money(25)
	supply_terminal.interact(player)
	_expect(wallet.get_money() == 25, "Failed supply purchase should not spend money.")
	_expect(inventory.get_amount("blank_cartridge") == starting_blank_amount, "Failed supply purchase should not add items.")
	_expect(_supply_statuses.has("Not enough money for Blank Cartridge Pack"), "Failed purchase should emit a status.")
	_expect(hud.status_message.text == "Not enough money for Blank Cartridge Pack", "HUD should show failed purchase status.")

	inventory.add_item("beach_loop", "Beach Loop", 1)
	sell_terminal.interact(player)
	_expect(wallet.get_money() == 50, "Selling Beach Loop should raise wallet to $50.")
	supply_terminal.interact(player)
	_expect(wallet.get_money() == 20, "Buying Blank Cartridge Pack should spend $30.")
	_expect(inventory.get_amount("blank_cartridge") == starting_blank_amount + 3, "Blank Cartridge Pack should add three cartridges.")
	_expect(hud.money_label.text == "Money: $20", "Wallet HUD should update after purchase.")
	_expect(_supply_statuses.has("Purchased Blank Cartridge Pack for $30"), "Purchase should emit a status.")
	_expect(hud.status_message.text == "Purchased Blank Cartridge Pack for $30", "HUD should show purchase status.")

	supply_terminal.secondary_interact(player)
	_expect(supply_terminal.get_selected_offer().id == "beach_starter_pack", "Cycling should select Beach Starter Pack.")
	_expect(_supply_statuses.has("Selected Beach Starter Pack"), "Cycling should emit a status.")
	hud.set_machine_panel_data(supply_terminal.get_interaction_panel_data(player))
	var panel_text := _get_panel_text(hud.machine_panel)
	_expect(hud.machine_panel.visible, "Supply panel should be visible.")
	_expect(hud.machine_panel.machine_name_label.text == "Supply Terminal", "Supply panel should show its machine name.")
	_expect(panel_text.contains("Beach Starter Pack"), "Supply panel should show selected offer.")
	_expect(panel_text.contains("Item: Beach Fragment"), "Supply panel should show received item.")
	_expect(panel_text.contains("Amount: 2"), "Supply panel should show received amount.")
	_expect(panel_text.contains("Price: $20"), "Supply panel should show price.")
	_expect(panel_text.contains("Wallet: $20"), "Supply panel should show wallet money.")
	_expect(hud.machine_panel.availability_label.text == "Can afford", "Supply panel should show affordability.")
	_expect(hud.machine_panel.controls_label.text == "E = Buy\nR = Switch Offer", "Supply panel should show controls.")

	var starting_beach_amount := inventory.get_amount("beach_fragment")
	supply_terminal.interact(player)
	_expect(wallet.get_money() == 0, "Buying Beach Starter Pack should spend $20.")
	_expect(inventory.get_amount("beach_fragment") == starting_beach_amount + 2, "Beach Starter Pack should add two fragments.")

	hud.set_machine_panel_data(supply_terminal.get_interaction_panel_data(player))
	_expect(hud.machine_panel.availability_label.text == "Not enough money", "Supply panel should refresh affordability.")

	inventory.add_item("penthouse", "Penthouse", 1)
	stash_box.interact(player)
	_expect(stash_box.get_contents().get("penthouse", 0) == 1, "Stash Box should still accept Lucids.")

	if _failures.is_empty():
		print("SUPPLY_TERMINAL_SMOKE_TEST: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("SUPPLY_TERMINAL_SMOKE_TEST: FAIL")
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _get_panel_text(panel: MachinePanel) -> String:
	var lines: PackedStringArray = [panel.machine_name_label.text]
	for child in panel.generic_sections.get_children():
		if child is Label:
			lines.append(child.text)
	lines.append(panel.availability_label.text)
	lines.append(panel.controls_label.text)
	return "\n".join(lines)
