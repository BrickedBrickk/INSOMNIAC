class_name SupplyOfferData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var item_id: String = ""
@export var item_display_name: String = ""
@export_range(1, 999, 1) var amount: int = 1
@export_range(1, 999999, 1) var price: int = 1
