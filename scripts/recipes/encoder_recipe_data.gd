class_name EncoderRecipeData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var output_item: LucidItemData
@export_range(1, 999, 1) var output_amount: int = 1
@export var ingredients: Array[ItemAmountData] = []
