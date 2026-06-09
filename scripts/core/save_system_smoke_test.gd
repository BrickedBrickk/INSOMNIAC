extends SceneTree

const SAVE_MANAGER_SCRIPT := preload("res://scripts/save/save_manager.gd")

var _failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main := main_scene.instantiate()
	root.add_child(main)

	await physics_frame
	await physics_frame

	var save_manager = SAVE_MANAGER_SCRIPT.new()
	var player: PlayerDesktopRig = main.get_node("Apartment/PlayerDesktopRig")
	var stash_box: StashBox = main.get_node("Apartment/StashBox")
	var encoder: DreamEncoder = main.get_node("Apartment/DreamEncoder")
	var supply_terminal: SupplyTerminal = main.get_node("Apartment/SupplyTerminal")
	var inventory := player.get_inventory()
	var wallet := player.get_wallet()

	_expect(save_manager.delete_save(), "Deleting an old test save should succeed.")
	_expect(not save_manager.has_save(), "No save should exist after deletion.")
	_expect(not save_manager.load_game(main), "Loading a missing save should fail safely.")

	wallet.set_money(321)
	_expect(inventory.set_items_from_save({"blank_cartridge": 4, "beach_loop": 2}), "Test inventory setup should succeed.")
	_expect(stash_box.load_contents_from_save({"penthouse": 3}), "Test stash setup should succeed.")
	encoder.set_selected_recipe_index(2)
	supply_terminal.set_selected_offer_index(4)
	player.global_position = Vector3(1.25, 1.5, -2.75)

	var save_data: Dictionary = save_manager.build_save_data(main)
	_expect(not save_data.is_empty(), "SaveManager should build save data.")
	_expect(save_data.has("wallet"), "Save data should include wallet state.")
	_expect(save_data.has("inventory"), "Save data should include inventory state.")
	_expect(save_data.has("stash_boxes"), "Save data should include stash boxes.")

	var wallet_data: Dictionary = save_data.get("wallet", {})
	var inventory_data: Dictionary = save_data.get("inventory", {})
	var stash_entries: Array = save_data.get("stash_boxes", [])
	_expect(wallet_data.get("money", -1) == 321, "Built save data should include wallet money.")
	_expect(inventory_data.get("blank_cartridge", 0) == 4, "Built save data should include inventory contents.")
	_expect(not stash_entries.is_empty(), "Built save data should include the existing stash.")
	if not stash_entries.is_empty():
		var stash_data: Dictionary = stash_entries[0].get("contents", {})
		_expect(stash_data.get("penthouse", 0) == 3, "Built save data should include stash contents.")

	_expect(save_manager.save_game(main), "Saving should succeed.")
	_expect(FileAccess.file_exists(save_manager.SAVE_PATH), "Save should be written to user://save_slot_1.json.")
	_expect(save_manager.has_save(), "has_save() should return true after saving.")

	wallet.set_money(0)
	inventory.clear()
	_expect(stash_box.load_contents_from_save({}), "Clearing the stash for the load test should succeed.")
	encoder.set_selected_recipe_index(0)
	supply_terminal.set_selected_offer_index(0)
	player.global_position = Vector3.ZERO

	_expect(save_manager.load_game(main), "Loading a valid save should succeed.")
	_expect(wallet.get_money() == 321, "Loading should restore wallet money.")
	_expect(inventory.get_amount("blank_cartridge") == 4, "Loading should restore inventory ingredients.")
	_expect(inventory.get_amount("beach_loop") == 2, "Loading should restore inventory Lucids.")
	_expect(stash_box.get_contents().get("penthouse", 0) == 3, "Loading should restore stash contents.")
	_expect(encoder.get_selected_recipe_index() == 2, "Loading should restore the selected encoder recipe.")
	_expect(supply_terminal.get_selected_offer_index() == 4, "Loading should restore the selected supply offer.")
	_expect(player.global_position.is_equal_approx(Vector3(1.25, 1.5, -2.75)), "Loading should restore player position.")

	var invalid_file := FileAccess.open(save_manager.SAVE_PATH, FileAccess.WRITE)
	_expect(invalid_file != null, "The invalid JSON test file should open.")
	if invalid_file != null:
		invalid_file.store_string("{ invalid json")
		invalid_file.flush()
		invalid_file.close()
	wallet.set_money(77)
	_expect(not save_manager.load_game(main), "Loading invalid JSON should fail safely.")
	_expect(wallet.get_money() == 77, "Invalid JSON should not alter current progress.")

	_expect(save_manager.delete_save(), "Deleting the test save should succeed.")
	_expect(not save_manager.has_save(), "The test save should be removed after the smoke test.")

	if _failures.is_empty():
		print("SAVE_SYSTEM_SMOKE_TEST: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("SAVE_SYSTEM_SMOKE_TEST: FAIL")
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
