class_name SellTerminal
extends StaticBody3D

signal status_changed(message: String)

const LUCID_PRICES: Dictionary = {
	"beach_loop": 25,
	"fast_life": 65,
	"penthouse": 90,
}
const LUCID_DISPLAY_NAMES: Dictionary = {
	"beach_loop": "Beach Loop",
	"fast_life": "Fast Life",
	"penthouse": "Penthouse",
}


func interact(player: Node) -> void:
	if not player.has_method("get_inventory") or not player.has_method("get_wallet"):
		push_warning("SellTerminal requires a player with inventory and wallet access.")
		return

	var inventory := player.call("get_inventory") as Inventory
	var wallet := player.call("get_wallet") as Wallet
	if inventory == null or wallet == null:
		push_warning("SellTerminal could not access the player's inventory or wallet.")
		return

	var total_earned := 0
	for item_id: String in LUCID_PRICES:
		var amount := inventory.get_amount(item_id)
		if amount <= 0:
			continue

		var earned: int = amount * LUCID_PRICES[item_id]
		if inventory.remove_item(item_id, amount):
			total_earned += earned
			print("SellTerminal: sold %s x%d for $%d" % [item_id, amount, earned])

	if total_earned <= 0:
		_notify("No Lucids to sell")
		return

	wallet.add_money(total_earned)
	_notify("Sold Lucids for $%d" % total_earned)


func get_interaction_prompt() -> String:
	return "Press E: Sell Lucids"


func get_interaction_panel_data(player: Node) -> Dictionary:
	var inventory: Inventory
	if player != null and player.has_method("get_inventory"):
		inventory = player.call("get_inventory") as Inventory

	var sale_lines: Array[String] = []
	var total_value := 0
	if inventory != null:
		for item_id: String in LUCID_PRICES:
			var amount := inventory.get_amount(item_id)
			if amount <= 0:
				continue

			var price: int = LUCID_PRICES[item_id]
			var item_total := amount * price
			total_value += item_total
			sale_lines.append("%s: %d x $%d = $%d" % [
				LUCID_DISPLAY_NAMES[item_id],
				amount,
				price,
				item_total,
			])

	var sections: Array[Dictionary] = []
	if sale_lines.is_empty():
		sections.append({"title": "No Lucids to sell.", "lines": []})
	else:
		sections.append({"title": "Ready to sell:", "lines": sale_lines})
		sections.append({"title": "Total: $%d" % total_value, "lines": []})

	return {
		"machine_name": "Sell Terminal",
		"sections": sections,
		"controls_text": "E = Sell Lucids",
	}


func _notify(message: String) -> void:
	print("SellTerminal: %s" % message)
	status_changed.emit(message)
