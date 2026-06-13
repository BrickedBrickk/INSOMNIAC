class_name CustomerOrderBoard
extends StaticBody3D

signal status_changed(message: String)

const REFRESH_COST: int = 50

@export var orders: Array[CustomerOrderData] = []
@export var selected_order_index: int = 0

var completed_orders: Dictionary = {}


func _ready() -> void:
	add_to_group("customer_order_boards")


func interact(player: Node) -> void:
	var order := get_selected_order()
	if order == null or not _is_valid_order(order):
		_notify("No valid selected order")
		return
	if completed_orders.has(order.id):
		_notify("%s is already completed" % order.order_title)
		return
	if (
		player == null
		or not player.has_method("get_inventory")
		or not player.has_method("get_wallet")
		or not player.has_method("get_player_stats")
	):
		push_warning("CustomerOrderBoard requires a player with inventory, wallet, and PlayerStats access.")
		return

	var inventory := player.call("get_inventory") as Inventory
	var wallet := player.call("get_wallet") as Wallet
	var player_stats := player.call("get_player_stats") as PlayerStats
	if inventory == null or wallet == null or player_stats == null:
		push_warning("CustomerOrderBoard could not access the player's inventory, wallet, or PlayerStats.")
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
	completed_orders[order.id] = true
	wallet.add_money(reward.money)
	player_stats.add_reputation(reward.reputation)
	player_stats.add_heat(reward.heat)
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


func refresh_orders(player: Node) -> bool:
	if completed_orders.is_empty():
		_notify("No completed orders to refresh.")
		return false
	if player == null or not player.has_method("get_wallet"):
		push_warning("CustomerOrderBoard requires a player with wallet access to refresh orders.")
		return false

	var wallet := player.call("get_wallet") as Wallet
	if wallet == null:
		push_warning("CustomerOrderBoard could not access the player's wallet to refresh orders.")
		return false
	if not wallet.spend_money(REFRESH_COST):
		_notify("Not enough money to refresh orders.")
		return false

	completed_orders.clear()
	_notify("Orders refreshed.")
	return true


func get_selected_order() -> CustomerOrderData:
	if orders.is_empty():
		return null
	selected_order_index = wrapi(selected_order_index, 0, orders.size())
	return orders[selected_order_index]


func get_selected_order_index() -> int:
	if orders.is_empty():
		return 0
	selected_order_index = clampi(selected_order_index, 0, orders.size() - 1)
	return selected_order_index


func set_selected_order_index(index: int) -> void:
	if orders.is_empty():
		selected_order_index = 0
		return
	selected_order_index = clampi(index, 0, orders.size() - 1)


func get_completed_orders_for_save() -> Array:
	var completed_ids: Array = completed_orders.keys()
	completed_ids.sort()
	return completed_ids


func load_completed_orders_from_save(data: Array) -> void:
	var loaded_completed_orders: Dictionary = {}
	for raw_order_id: Variant in data:
		if typeof(raw_order_id) != TYPE_STRING:
			continue
		var order_id := str(raw_order_id)
		if _has_order_id(order_id):
			loaded_completed_orders[order_id] = true
	completed_orders = loaded_completed_orders


func get_order_state_for_save() -> Dictionary:
	return {
		"selected_order_index": get_selected_order_index(),
		"completed_orders": get_completed_orders_for_save(),
	}


func load_order_state_from_save(data: Dictionary) -> void:
	var saved_index: Variant = data.get("selected_order_index")
	if _is_number(saved_index):
		set_selected_order_index(int(saved_index))

	var saved_completed_orders: Variant = data.get("completed_orders")
	if typeof(saved_completed_orders) == TYPE_ARRAY:
		load_completed_orders_from_save(saved_completed_orders)


func get_interaction_prompt() -> String:
	return "Press E: Fulfill Order"


func get_interaction_panel_data(player: Node) -> Dictionary:
	var order := get_selected_order()
	if order == null:
		return {
			"machine_name": "Customer Orders",
			"sections": [_get_refresh_panel_section()],
			"status_text": "No orders available",
			"controls_text": "E = Fulfill Order\nR = Switch Order",
		}

	var inventory: Inventory
	if player != null and player.has_method("get_inventory"):
		inventory = player.call("get_inventory") as Inventory
	var owned_amount := inventory.get_amount(order.requested_item_id) if inventory != null else 0
	var is_completed := completed_orders.has(order.id)
	var can_fulfill := (
		not is_completed
		and inventory != null
		and _is_valid_order(order)
		and owned_amount >= order.requested_amount
	)

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
			_get_refresh_panel_section(),
		],
		"status_text": (
			"COMPLETED"
			if is_completed
			else "Ready to fulfill" if can_fulfill else "Missing requested Lucid"
		),
		"controls_text": "E = Fulfill Order\nR = Switch Order",
	}


func _get_refresh_panel_section() -> Dictionary:
	return {
		"title": "Refresh:",
		"lines": [
			"F = Refresh Orders ($%d)" % REFRESH_COST,
			"Refresh available." if not completed_orders.is_empty() else "No completed orders to refresh.",
		],
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


func _has_order_id(order_id: String) -> bool:
	for order: CustomerOrderData in orders:
		if order != null and order.id == order_id:
			return true
	return false


func _notify(message: String) -> void:
	print("Customer Order Board: %s" % message)
	status_changed.emit(message)


func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
