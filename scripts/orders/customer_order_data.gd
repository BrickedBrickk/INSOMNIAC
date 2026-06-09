class_name CustomerOrderData
extends Resource

@export var id: String = ""
@export var customer_name: String = ""
@export var order_title: String = ""
@export var requested_item_id: String = ""
@export var requested_item_display_name: String = ""
@export_range(1, 999, 1) var requested_amount: int = 1
@export_range(0, 999999, 1) var payout: int = 0
@export_range(0, 999999, 1) var reputation_gain: int = 0
@export_range(0, 999999, 1) var heat_gain: int = 0
@export_multiline var flavor_text: String = ""


func get_reward() -> OrderRewardData:
	var reward := OrderRewardData.new()
	reward.money = payout
	reward.reputation = reputation_gain
	reward.heat = heat_gain
	return reward
