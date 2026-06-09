class_name CustomerOrderBoard
extends StaticBody3D

signal status_changed(message: String)

@export var orders: Array[CustomerOrderData] = []
@export var selected_order_index: int = 0


func interact(player: Node) -> void:
	var order := get_selected_order()
	if order == null or not _is_valid_order(order):
		_notify("No valid selected order")
		return
	if player == null or not player.has_method("get_inventory") or not player.has_method("get_wallet"):
		push_warning("CustomerOrderBoard requires a player with inventory and wallet access.")
		return

	var inventory := player.call("get_inventory") as Inventory
	var wallet := player.call("get_wallet") as Wallet
	if inventory == null or wallet == null:
		push_warning("CustomerOrderBoard could not access the player's inventory or wallet.")
		return

	var owned_amount := inventory.get_amount(order.requested_item_id)
	if owned_amount < order.requested_amount:
		_notify("Missing %s: %d / %d" % [
			order.requested_item_display_name,
			owned_amount,
			order.requested_amount,
		])
		return
	if not inventory.remove_item(order.requested_item_id, order.requested_amount):
		_notify("Could not remove %s" % order.requested_item_display_name)
		return

	var reward := order.get_reward()
	wallet.add_money(reward.money)
	print("Customer Order Board: reputation +%d, heat +%d" % [reward.reputation, reward.heat])
	_notify("Fulfilled %s for $%d" % [order.order_title, reward.money])
	_advance_order()


func secondary_interact(_player: Node) -> void:
	if orders.is_empty():
		_notify("No orders available")
		return

	_advance_order()
	var order := get_selected_order()
	if order != null:
		_notify("Selected %s" % order.order_title)


func get_selected_order() -> CustomerOrderData:
	if orders.is_empty():
		return null
	selected_order_index = wrapi(selected_order_index, 0, orders.size())
	return orders[selected_order_index]


func get_interaction_prompt() -> String:
	return "Press E: Fulfill Order"


func get_interaction_panel_data(player: Node) -> Dictionary:
	var order := get_selected_order()
	if order == null:
		return {
			"machine_name": "Customer Orders",
			"sections": [],
			"status_text": "No orders available",
			"controls_text": "E = Fulfill Order\nR = Switch Order",
		}

	var inventory: Inventory
	if player != null and player.has_method("get_inventory"):
		inventory = player.call("get_inventory") as Inventory
	var owned_amount := inventory.get_amount(order.requested_item_id) if inventory != null else 0
	var can_fulfill := inventory != null and _is_valid_order(order) and owned_amount >= order.requested_amount

	return {
		"machine_name": "Customer Orders",
		"sections": [
			{
				"title": "Selected Order:",
				"lines": [order.order_title],
			},
			{
				"title": "Customer:",
				"lines": [order.customer_name],
			},
			{
				"title": "Request:",
				"lines": [
					"Item: %s" % order.requested_item_display_name,
					"Owned / Required: %d / %d" % [owned_amount, order.requested_amount],
				],
			},
			{
				"title": "Rewards:",
				"lines": [
					"Payout: $%d" % order.payout,
					"Reputation: +%d" % order.reputation_gain,
					"Heat: +%d" % order.heat_gain,
				],
			},
			{
				"title": "Message:",
				"lines": [order.flavor_text],
			},
		],
		"status_text": "Ready to fulfill" if can_fulfill else "Missing requested Lucid",
		"controls_text": "E = Fulfill Order\nR = Switch Order",
	}


func _advance_order() -> void:
	if not orders.is_empty():
		selected_order_index = wrapi(selected_order_index + 1, 0, orders.size())


func _is_valid_order(order: CustomerOrderData) -> bool:
	return (
		not order.id.is_empty()
		and not order.customer_name.is_empty()
		and not order.order_title.is_empty()
		and not order.requested_item_id.is_empty()
		and not order.requested_item_display_name.is_empty()
		and order.requested_amount > 0
		and order.payout >= 0
		and order.reputation_gain >= 0
		and order.heat_gain >= 0
	)


func _notify(message: String) -> void:
	print("Customer Order Board: %s" % message)
	status_changed.emit(message)
