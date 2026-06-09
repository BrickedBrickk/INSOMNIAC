class_name ItemAmountData
extends Resource

@export var item_id: String = ""
@export var display_name: String = ""
@export_range(1, 999, 1) var amount: int = 1
