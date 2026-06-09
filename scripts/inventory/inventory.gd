class_name Inventory
extends Node

signal inventory_changed

@export var starting_items: Array[ItemAmountData] = []

var _stacks: Dictionary = {}


func _ready() -> void:
	for item in starting_items:
		if item != null:
			add_item(item.item_id, item.display_name, item.amount)


func add_item(id: String, display_name: String, amount: int = 1) -> void:
	if id.is_empty() or amount <= 0:
		return

	if _stacks.has(id):
		var existing_stack: ItemStack = _stacks[id]
		existing_stack.amount += amount
	else:
		_stacks[id] = ItemStack.new(id, display_name, amount)

	inventory_changed.emit()
	print("Inventory: added %s x%d" % [display_name, amount])


func has_items(items: Array[ItemAmountData]) -> bool:
	var requirements := _get_requirements(items)
	if requirements.is_empty() and not items.is_empty():
		return false

	for item_id: String in requirements:
		if get_item_amount(item_id) < requirements[item_id]:
			return false
	return true


func remove_items(items: Array[ItemAmountData]) -> bool:
	if not has_items(items):
		return false

	var requirements := _get_requirements(items)
	for item_id: String in requirements:
		var stack: ItemStack = _stacks[item_id]
		stack.amount -= requirements[item_id]
		print("Inventory: removed %s x%d" % [stack.display_name, requirements[item_id]])
		if stack.amount <= 0:
			_stacks.erase(item_id)

	inventory_changed.emit()
	return true


func get_item_amount(id: String) -> int:
	if not _stacks.has(id):
		return 0
	var stack: ItemStack = _stacks[id]
	return stack.amount


func get_amount(item_id: String) -> int:
	return get_item_amount(item_id)


func remove_item(item_id: String, amount: int) -> bool:
	if item_id.is_empty() or amount <= 0 or get_item_amount(item_id) < amount:
		return false

	var stack: ItemStack = _stacks[item_id]
	stack.amount -= amount
	print("Inventory: removed %s x%d" % [stack.display_name, amount])
	if stack.amount <= 0:
		_stacks.erase(item_id)

	inventory_changed.emit()
	return true


func get_all_items() -> Dictionary:
	var items: Dictionary = {}
	for item_id: String in _stacks:
		var stack: ItemStack = _stacks[item_id]
		items[item_id] = stack.amount
	return items


func get_debug_text() -> String:
	if _stacks.is_empty():
		return "Inventory:\n(empty)"

	var lines: PackedStringArray = ["Inventory:"]
	var ids := _stacks.keys()
	ids.sort()
	for id: String in ids:
		var stack: ItemStack = _stacks[id]
		lines.append("%s x%d" % [stack.display_name, stack.amount])
	return "\n".join(lines)


func _get_requirements(items: Array[ItemAmountData]) -> Dictionary:
	var requirements: Dictionary = {}
	for item in items:
		if item == null or item.item_id.is_empty() or item.amount <= 0:
			return {}
		requirements[item.item_id] = requirements.get(item.item_id, 0) + item.amount
	return requirements
