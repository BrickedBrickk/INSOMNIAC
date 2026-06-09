class_name StashBox
extends StaticBody3D

signal status_changed(message: String)

const LUCID_ITEM_IDS: PackedStringArray = [
	"beach_loop",
	"fast_life",
	"penthouse",
]
const LUCID_DISPLAY_NAMES: Dictionary = {
	"beach_loop": "Beach Loop",
	"fast_life": "Fast Life",
	"penthouse": "Penthouse",
}

var _contents: Dictionary = {}


func interact(player: Node) -> void:
	if not player.has_method("get_inventory"):
		push_warning("StashBox requires a player with inventory access.")
		return

	var inventory := player.call("get_inventory") as Inventory
	if inventory == null:
		push_warning("StashBox could not access the player's inventory.")
		return

	var deposited_any := false
	for item_id: String in LUCID_ITEM_IDS:
		var amount := inventory.get_amount(item_id)
		if amount > 0 and inventory.remove_item(item_id, amount):
			_contents[item_id] = _contents.get(item_id, 0) + amount
			deposited_any = true
			print("StashBox: deposited %s x%d" % [item_id, amount])

	print("Stash contents: %s" % [_contents])
	if deposited_any:
		_notify("Deposited Lucids into stash")
	else:
		_notify("No Lucids to deposit")


func get_interaction_prompt() -> String:
	return "Press E: Deposit Lucids"


func get_contents() -> Dictionary:
	return _contents.duplicate()


func get_interaction_panel_data(player: Node) -> Dictionary:
	var inventory: Inventory
	if player != null and player.has_method("get_inventory"):
		inventory = player.call("get_inventory") as Inventory

	var deposit_lines: Array[String] = []
	if inventory != null:
		for item_id: String in LUCID_ITEM_IDS:
			var amount := inventory.get_amount(item_id)
			if amount > 0:
				deposit_lines.append("%s: %d" % [LUCID_DISPLAY_NAMES[item_id], amount])

	var stash_lines: Array[String] = []
	for item_id: String in LUCID_ITEM_IDS:
		var amount: int = _contents.get(item_id, 0)
		if amount > 0:
			stash_lines.append("%s: %d" % [LUCID_DISPLAY_NAMES[item_id], amount])
	if stash_lines.is_empty():
		stash_lines.append("(empty)")

	var sections: Array[Dictionary] = []
	if deposit_lines.is_empty():
		sections.append({"title": "No Lucids to deposit.", "lines": []})
	else:
		sections.append({"title": "Deposit from inventory:", "lines": deposit_lines})
	sections.append({"title": "Stash contents:", "lines": stash_lines})

	return {
		"machine_name": "Stash Box",
		"sections": sections,
		"controls_text": "E = Deposit Lucids",
	}


func _notify(message: String) -> void:
	print("StashBox: %s" % message)
	status_changed.emit(message)
