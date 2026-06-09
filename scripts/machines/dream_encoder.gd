class_name DreamEncoder
extends Interactable

signal status_changed(message: String)
signal recipe_changed(recipe: EncoderRecipeData)

@export var encode_duration: float = 2.0
@export var recipes: Array[EncoderRecipeData] = []
@export var selected_recipe_index: int = 0

var _is_encoding: bool = false
var _pending_player: Node
var _pending_recipe: EncoderRecipeData
var _encode_started_msec: int = 0


func _ready() -> void:
	add_to_group("dream_encoders")


func interact(player: Node) -> void:
	if _is_encoding:
		_notify("Encoder already running")
		return

	var recipe := get_selected_recipe()
	if recipe == null or recipe.output_item == null:
		_notify("Encoder has no valid selected recipe")
		return
	if not player.has_method("get_inventory"):
		_notify("Encoding failed: inventory unavailable")
		return

	var inventory: Inventory = player.get_inventory()
	if not inventory.has_items(recipe.ingredients):
		_notify("Missing ingredients for %s" % recipe.display_name)
		return
	if not inventory.remove_items(recipe.ingredients):
		_notify("Missing ingredients for %s" % recipe.display_name)
		return

	_is_encoding = true
	_pending_player = player
	_pending_recipe = recipe
	_encode_started_msec = Time.get_ticks_msec()
	_notify("Encoding %s..." % recipe.display_name)
	await get_tree().create_timer(encode_duration).timeout
	_finish_encoding()


func secondary_interact(_player: Node) -> void:
	if recipes.is_empty():
		_notify("Encoder has no recipes")
		return

	selected_recipe_index = wrapi(selected_recipe_index + 1, 0, recipes.size())
	var recipe := get_selected_recipe()
	recipe_changed.emit(recipe)
	_notify("Selected recipe: %s" % recipe.display_name)


func get_selected_recipe() -> EncoderRecipeData:
	if recipes.is_empty():
		return null
	selected_recipe_index = wrapi(selected_recipe_index, 0, recipes.size())
	return recipes[selected_recipe_index]


func get_selected_recipe_index() -> int:
	if recipes.is_empty():
		return 0
	selected_recipe_index = clampi(selected_recipe_index, 0, recipes.size() - 1)
	return selected_recipe_index


func set_selected_recipe_index(index: int) -> void:
	if recipes.is_empty():
		selected_recipe_index = 0
		return
	selected_recipe_index = clampi(index, 0, recipes.size() - 1)


func get_interaction_prompt() -> String:
	var recipe := get_selected_recipe()
	if recipe == null:
		return "Press E: Dream Encoder\nPress R: Switch Recipe"
	return "Press E: Encode %s\nPress R: Switch Recipe" % recipe.display_name


func get_interaction_panel_data(player: Node) -> Dictionary:
	var recipe := get_selected_recipe()
	if recipe == null or recipe.output_item == null:
		return {
			"machine_name": prompt_name,
			"selected_recipe_name": "Unavailable",
			"output_name": "Unavailable",
			"output_stats": {},
			"ingredients": [],
			"is_running": _is_encoding,
			"progress_percent": get_progress_percent(),
			"controls_text": "E = Encode\nR = Switch Recipe",
			"can_encode": false,
		}

	var inventory: Inventory
	if player != null and player.has_method("get_inventory"):
		inventory = player.get_inventory()

	var ingredient_data: Array[Dictionary] = []
	for ingredient in recipe.ingredients:
		if ingredient == null:
			continue
		var owned_amount := inventory.get_item_amount(ingredient.item_id) if inventory != null else 0
		ingredient_data.append({
			"item_id": ingredient.item_id,
			"display_name": ingredient.display_name,
			"owned_amount": owned_amount,
			"required_amount": ingredient.amount,
			"is_missing": owned_amount < ingredient.amount,
		})

	return {
		"machine_name": prompt_name,
		"selected_recipe_name": recipe.display_name,
		"output_name": recipe.output_item.display_name,
		"output_stats": _get_output_stats(recipe.output_item),
		"ingredients": ingredient_data,
		"is_running": _is_encoding,
		"progress_percent": get_progress_percent(),
		"controls_text": "E = Encode\nR = Switch Recipe",
		"can_encode": not _is_encoding and inventory != null and inventory.has_items(recipe.ingredients),
	}


func get_progress_percent() -> int:
	if not _is_encoding:
		return 0
	if encode_duration <= 0.0:
		return 100

	var elapsed_seconds := float(Time.get_ticks_msec() - _encode_started_msec) / 1000.0
	return clampi(int((elapsed_seconds / encode_duration) * 100.0), 0, 100)


func _finish_encoding() -> void:
	if (
		not is_instance_valid(_pending_player)
		or not _pending_player.has_method("get_inventory")
		or _pending_recipe == null
		or _pending_recipe.output_item == null
	):
		_clear_pending_encode()
		_notify("Encoding failed: output unavailable")
		return

	var inventory: Inventory = _pending_player.get_inventory()
	var output := _pending_recipe.output_item
	var output_amount := _pending_recipe.output_amount
	inventory.add_item(output.id, output.display_name, output_amount)

	_clear_pending_encode()
	_notify("Encoded %s x%d" % [output.display_name, output_amount])


func _clear_pending_encode() -> void:
	_is_encoding = false
	_pending_player = null
	_pending_recipe = null
	_encode_started_msec = 0


func _get_output_stats(output_item: LucidItemData) -> Dictionary:
	return {
		"clarity": output_item.clarity,
		"intensity": output_item.intensity,
		"stability": output_item.stability,
		"duration": output_item.duration,
		"heat": output_item.heat,
		"value": output_item.value,
		"corruption": output_item.corruption,
	}


func _notify(message: String) -> void:
	print("Dream Encoder: %s" % message)
	status_changed.emit(message)
