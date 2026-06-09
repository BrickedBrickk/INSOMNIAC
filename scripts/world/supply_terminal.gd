class_name SupplyTerminal
extends StaticBody3D

signal status_changed(message: String)

@export var offers: Array[SupplyOfferData] = []
@export var selected_offer_index: int = 0


func _ready() -> void:
	add_to_group("supply_terminals")


func interact(player: Node) -> void:
	var offer := get_selected_offer()
	if offer == null or not _is_valid_offer(offer):
		_notify("No valid selected offer")
		return
	if not player.has_method("get_inventory") or not player.has_method("get_wallet"):
		push_warning("SupplyTerminal requires a player with inventory and wallet access.")
		return

	var inventory := player.call("get_inventory") as Inventory
	var wallet := player.call("get_wallet") as Wallet
	if inventory == null or wallet == null:
		push_warning("SupplyTerminal could not access the player's inventory or wallet.")
		return
	if not wallet.spend_money(offer.price):
		_notify("Not enough money for %s" % offer.display_name)
		return

	inventory.add_item(offer.item_id, offer.item_display_name, offer.amount)
	_notify("Purchased %s for $%d" % [offer.display_name, offer.price])


func secondary_interact(_player: Node) -> void:
	if offers.is_empty():
		_notify("No offers available")
		return

	selected_offer_index = wrapi(selected_offer_index + 1, 0, offers.size())
	var offer := get_selected_offer()
	if offer != null:
		_notify("Selected %s" % offer.display_name)


func get_selected_offer() -> SupplyOfferData:
	if offers.is_empty():
		return null
	selected_offer_index = wrapi(selected_offer_index, 0, offers.size())
	return offers[selected_offer_index]


func get_selected_offer_index() -> int:
	if offers.is_empty():
		return 0
	selected_offer_index = clampi(selected_offer_index, 0, offers.size() - 1)
	return selected_offer_index


func set_selected_offer_index(index: int) -> void:
	if offers.is_empty():
		selected_offer_index = 0
		return
	selected_offer_index = clampi(index, 0, offers.size() - 1)


func get_interaction_prompt() -> String:
	return "Press E: Buy Supplies"


func get_interaction_panel_data(player: Node) -> Dictionary:
	var offer := get_selected_offer()
	if offer == null:
		return {
			"machine_name": "Supply Terminal",
			"sections": [],
			"status_text": "No offers available",
			"controls_text": "E = Buy\nR = Switch Offer",
		}

	var wallet: Wallet
	if player != null and player.has_method("get_wallet"):
		wallet = player.call("get_wallet") as Wallet
	var money := wallet.get_money() if wallet != null else 0
	var can_buy := wallet != null and _is_valid_offer(offer) and wallet.can_afford(offer.price)

	return {
		"machine_name": "Supply Terminal",
		"sections": [
			{
				"title": "Selected Offer:",
				"lines": [offer.display_name],
			},
			{
				"title": "Purchase:",
				"lines": [
					"Item: %s" % offer.item_display_name,
					"Amount: %d" % offer.amount,
					"Price: $%d" % offer.price,
					"Wallet: $%d" % money,
				],
			},
		],
		"status_text": "Can afford" if can_buy else "Not enough money",
		"controls_text": "E = Buy\nR = Switch Offer",
	}


func _is_valid_offer(offer: SupplyOfferData) -> bool:
	return (
		not offer.id.is_empty()
		and not offer.display_name.is_empty()
		and not offer.item_id.is_empty()
		and not offer.item_display_name.is_empty()
		and offer.amount > 0
		and offer.price > 0
	)


func _notify(message: String) -> void:
	print("Supply Terminal: %s" % message)
	status_changed.emit(message)
