class_name ItemStack
extends RefCounted

var id: String
var display_name: String
var amount: int


func _init(item_id: String, item_display_name: String, item_amount: int) -> void:
	id = item_id
	display_name = item_display_name
	amount = item_amount
