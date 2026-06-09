class_name SaveManager
extends RefCounted

const SAVE_VERSION: int = 1
const SAVE_FILE_NAME: String = "save_slot_1.json"
const SAVE_PATH: String = "user://save_slot_1.json"


func save_game(root_or_game_node) -> bool:
	var root := _resolve_root(root_or_game_node)
	if root == null:
		push_warning("SaveManager: cannot save without a valid root node.")
		return false

	var data := build_save_data(root)
	if not data.has("wallet") or not data.has("inventory"):
		push_warning("SaveManager: save data is missing required economy state.")
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: could not open %s for writing. Error: %s" % [
			SAVE_PATH,
			FileAccess.get_open_error(),
		])
		return false

	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	print("SaveManager: saved game to %s" % SAVE_PATH)
	return true


func load_game(root_or_game_node) -> bool:
	var root := _resolve_root(root_or_game_node)
	if root == null:
		push_warning("SaveManager: cannot load without a valid root node.")
		return false
	if not has_save():
		print("SaveManager: no save file found at %s" % SAVE_PATH)
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SaveManager: could not open %s for reading. Error: %s" % [
			SAVE_PATH,
			FileAccess.get_open_error(),
		])
		return false

	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		push_warning("SaveManager: invalid JSON in %s at line %d: %s" % [
			SAVE_PATH,
			json.get_error_line(),
			json.get_error_message(),
		])
		return false
	if typeof(json.data) != TYPE_DICTIONARY:
		push_warning("SaveManager: save root must be a JSON object.")
		return false

	var loaded := apply_save_data(root, json.data)
	if loaded:
		print("SaveManager: loaded game from %s" % SAVE_PATH)
	else:
		push_warning("SaveManager: save data could not be applied safely.")
	return loaded


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> bool:
	if not has_save():
		print("SaveManager: no save file to delete at %s" % SAVE_PATH)
		return true

	var user_directory := DirAccess.open("user://")
	if user_directory == null:
		push_warning("SaveManager: could not open user:// to delete the save.")
		return false

	var remove_error := user_directory.remove(SAVE_FILE_NAME)
	if remove_error != OK:
		push_warning("SaveManager: could not delete %s. Error: %s" % [SAVE_PATH, remove_error])
		return false

	print("SaveManager: deleted %s" % SAVE_PATH)
	return true


func build_save_data(root_or_game_node) -> Dictionary:
	var root := _resolve_root(root_or_game_node)
	var data: Dictionary = {"save_version": SAVE_VERSION}
	if root == null:
		push_warning("SaveManager: cannot build save data without a valid root node.")
		return data

	var player := _find_player(root)
	var inventory := _find_inventory(root, player)
	var wallet := _find_wallet(root, player)
	if wallet != null:
		data["wallet"] = {"money": wallet.call("get_money")}
	else:
		push_warning("SaveManager: wallet was not found while building save data.")
	if inventory != null:
		data["inventory"] = inventory.call("get_all_items")
	else:
		push_warning("SaveManager: inventory was not found while building save data.")

	var stash_data: Array[Dictionary] = []
	for stash_box: Node in _find_nodes(root, "stash_boxes", ["get_contents_for_save", "load_contents_from_save"]):
		stash_data.append({
			"node_path": str(root.get_path_to(stash_box)),
			"contents": stash_box.call("get_contents_for_save"),
		})
	data["stash_boxes"] = stash_data

	var encoder_data: Array[Dictionary] = []
	for encoder: Node in _find_nodes(
		root,
		"dream_encoders",
		["get_selected_recipe_index", "set_selected_recipe_index"]
	):
		encoder_data.append({
			"node_path": str(root.get_path_to(encoder)),
			"selected_recipe_index": encoder.call("get_selected_recipe_index"),
		})
	data["dream_encoders"] = encoder_data

	var supply_data: Array[Dictionary] = []
	for terminal: Node in _find_nodes(
		root,
		"supply_terminals",
		["get_selected_offer_index", "set_selected_offer_index"]
	):
		supply_data.append({
			"node_path": str(root.get_path_to(terminal)),
			"selected_offer_index": terminal.call("get_selected_offer_index"),
		})
	data["supply_terminals"] = supply_data

	var customer_order_data: Array[Dictionary] = []
	for board: Node in _find_nodes(
		root,
		"customer_order_boards",
		["get_order_state_for_save", "load_order_state_from_save"]
	):
		var order_state: Dictionary = board.call("get_order_state_for_save")
		order_state["node_path"] = str(root.get_path_to(board))
		customer_order_data.append(order_state)
	data["customer_order_boards"] = customer_order_data

	if player is Node3D:
		var position: Vector3 = player.global_position
		data["player_position"] = {"x": position.x, "y": position.y, "z": position.z}

	return data


func apply_save_data(root_or_game_node, data: Dictionary) -> bool:
	var root := _resolve_root(root_or_game_node)
	if root == null:
		push_warning("SaveManager: cannot apply save data without a valid root node.")
		return false
	if not _has_supported_version(data):
		return false

	var player := _find_player(root)
	var inventory := _find_inventory(root, player)
	var wallet := _find_wallet(root, player)
	if inventory == null or wallet == null:
		push_warning("SaveManager: required inventory or wallet node was not found.")
		return false

	var wallet_data: Variant = data.get("wallet")
	var inventory_data: Variant = data.get("inventory")
	if typeof(wallet_data) != TYPE_DICTIONARY or typeof(inventory_data) != TYPE_DICTIONARY:
		push_warning("SaveManager: save data is missing valid wallet or inventory sections.")
		return false

	var money: Variant = wallet_data.get("money")
	if not _is_number(money):
		push_warning("SaveManager: wallet money is invalid.")
		return false

	wallet.call("set_money", maxi(int(money), 0))
	var applied_cleanly := bool(inventory.call("set_items_from_save", inventory_data))
	applied_cleanly = _apply_stash_data(root, data) and applied_cleanly
	applied_cleanly = _apply_encoder_data(root, data) and applied_cleanly
	applied_cleanly = _apply_supply_data(root, data) and applied_cleanly
	applied_cleanly = _apply_customer_order_data(root, data) and applied_cleanly
	applied_cleanly = _apply_player_position(player, data) and applied_cleanly
	return applied_cleanly


func _apply_stash_data(root: Node, data: Dictionary) -> bool:
	if not data.has("stash_boxes"):
		return true
	var entries: Variant = data["stash_boxes"]
	if typeof(entries) != TYPE_ARRAY:
		push_warning("SaveManager: stash_boxes must be an array.")
		return false

	var applied_cleanly := true
	var nodes := _find_nodes(root, "stash_boxes", ["get_contents_for_save", "load_contents_from_save"])
	for index: int in nodes.size():
		var entry := _find_entry(entries, root, nodes[index], index)
		if entry.is_empty():
			continue
		var contents: Variant = entry.get("contents")
		if typeof(contents) != TYPE_DICTIONARY:
			applied_cleanly = false
			continue
		applied_cleanly = bool(nodes[index].call("load_contents_from_save", contents)) and applied_cleanly
	return applied_cleanly


func _apply_encoder_data(root: Node, data: Dictionary) -> bool:
	if not data.has("dream_encoders"):
		return true
	var entries: Variant = data["dream_encoders"]
	if typeof(entries) != TYPE_ARRAY:
		push_warning("SaveManager: dream_encoders must be an array.")
		return false

	var applied_cleanly := true
	var nodes := _find_nodes(
		root,
		"dream_encoders",
		["get_selected_recipe_index", "set_selected_recipe_index"]
	)
	for index: int in nodes.size():
		var entry := _find_entry(entries, root, nodes[index], index)
		if entry.is_empty():
			continue
		var selected_index: Variant = entry.get("selected_recipe_index")
		if not _is_number(selected_index):
			applied_cleanly = false
			continue
		nodes[index].call("set_selected_recipe_index", int(selected_index))
	return applied_cleanly


func _apply_supply_data(root: Node, data: Dictionary) -> bool:
	if not data.has("supply_terminals"):
		return true
	var entries: Variant = data["supply_terminals"]
	if typeof(entries) != TYPE_ARRAY:
		push_warning("SaveManager: supply_terminals must be an array.")
		return false

	var applied_cleanly := true
	var nodes := _find_nodes(
		root,
		"supply_terminals",
		["get_selected_offer_index", "set_selected_offer_index"]
	)
	for index: int in nodes.size():
		var entry := _find_entry(entries, root, nodes[index], index)
		if entry.is_empty():
			continue
		var selected_index: Variant = entry.get("selected_offer_index")
		if not _is_number(selected_index):
			applied_cleanly = false
			continue
		nodes[index].call("set_selected_offer_index", int(selected_index))
	return applied_cleanly


func _apply_customer_order_data(root: Node, data: Dictionary) -> bool:
	if not data.has("customer_order_boards"):
		return true
	var entries: Variant = data["customer_order_boards"]
	if typeof(entries) != TYPE_ARRAY:
		push_warning("SaveManager: customer_order_boards must be an array.")
		return false

	var applied_cleanly := true
	var nodes := _find_nodes(
		root,
		"customer_order_boards",
		["get_order_state_for_save", "load_order_state_from_save"]
	)
	for index: int in nodes.size():
		var entry := _find_entry(entries, root, nodes[index], index)
		if entry.is_empty():
			continue
		var selected_index: Variant = entry.get("selected_order_index")
		var completed_orders: Variant = entry.get("completed_orders")
		if not _is_number(selected_index) or typeof(completed_orders) != TYPE_ARRAY:
			applied_cleanly = false
			continue
		nodes[index].call("load_order_state_from_save", entry)
	return applied_cleanly


func _apply_player_position(player: Node, data: Dictionary) -> bool:
	if not data.has("player_position"):
		return true
	if not player is Node3D:
		push_warning("SaveManager: player position exists but the player is not a Node3D.")
		return false

	var position_data: Variant = data["player_position"]
	if typeof(position_data) != TYPE_DICTIONARY:
		push_warning("SaveManager: player_position must be an object.")
		return false

	var x: Variant = position_data.get("x")
	var y: Variant = position_data.get("y")
	var z: Variant = position_data.get("z")
	if not _is_number(x) or not _is_number(y) or not _is_number(z):
		push_warning("SaveManager: player_position contains invalid coordinates.")
		return false

	player.global_position = Vector3(float(x), float(y), float(z))
	return true


func _has_supported_version(data: Dictionary) -> bool:
	var version: Variant = data.get("save_version")
	if not _is_number(version):
		push_warning("SaveManager: save_version is missing or invalid.")
		return false
	if int(version) != SAVE_VERSION:
		push_warning("SaveManager: unsupported save version %s." % version)
		return false
	return true


func _find_entry(entries: Array, root: Node, node: Node, fallback_index: int) -> Dictionary:
	var node_path := str(root.get_path_to(node))
	for raw_entry: Variant in entries:
		if typeof(raw_entry) == TYPE_DICTIONARY and str(raw_entry.get("node_path", "")) == node_path:
			return raw_entry
	if fallback_index < entries.size() and typeof(entries[fallback_index]) == TYPE_DICTIONARY:
		return entries[fallback_index]
	return {}


func _find_player(root: Node) -> Node:
	var players := _find_nodes(root, "player", ["get_inventory", "get_wallet"])
	return players[0] if not players.is_empty() else null


func _find_inventory(root: Node, player: Node) -> Node:
	if player != null and player.has_method("get_inventory"):
		var inventory: Variant = player.call("get_inventory")
		if inventory is Node and inventory.has_method("get_all_items") and inventory.has_method("set_items_from_save"):
			return inventory
	var inventories := _find_nodes(root, "", ["get_all_items", "set_items_from_save"])
	return inventories[0] if not inventories.is_empty() else null


func _find_wallet(root: Node, player: Node) -> Node:
	if player != null and player.has_method("get_wallet"):
		var wallet: Variant = player.call("get_wallet")
		if wallet is Node and wallet.has_method("get_money") and wallet.has_method("set_money"):
			return wallet
	var wallets := _find_nodes(root, "", ["get_money", "set_money"])
	return wallets[0] if not wallets.is_empty() else null


func _find_nodes(root: Node, group_name: StringName, required_methods: Array) -> Array[Node]:
	var matches: Array[Node] = []
	if not group_name.is_empty() and root.get_tree() != null:
		for node: Node in root.get_tree().get_nodes_in_group(group_name):
			if _is_in_scope(root, node) and _has_methods(node, required_methods):
				matches.append(node)
	_collect_matching_nodes(root, required_methods, matches)
	return matches


func _collect_matching_nodes(node: Node, required_methods: Array, matches: Array[Node]) -> void:
	if _has_methods(node, required_methods) and not matches.has(node):
		matches.append(node)
	for child: Node in node.get_children():
		_collect_matching_nodes(child, required_methods, matches)


func _has_methods(node: Node, required_methods: Array) -> bool:
	for method_name: StringName in required_methods:
		if not node.has_method(method_name):
			return false
	return true


func _is_in_scope(root: Node, node: Node) -> bool:
	return root == node or root.is_ancestor_of(node)


func _resolve_root(root_or_game_node) -> Node:
	if root_or_game_node is Node:
		return root_or_game_node
	if root_or_game_node is SceneTree:
		if root_or_game_node.current_scene != null:
			return root_or_game_node.current_scene
		return root_or_game_node.root
	return null


func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
