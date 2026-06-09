extends SceneTree

const SAVE_MANAGER_SCRIPT := preload("res://scripts/save/save_manager.gd")

var _failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	_expect(main_scene != null, "Main scene should load.")
	if main_scene == null:
		_finish(null)
		return

	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var save_manager = SAVE_MANAGER_SCRIPT.new()
	var player: PlayerDesktopRig = main.get_node("Apartment/PlayerDesktopRig")
	var hud: HUD = main.get_node("HUD")
	var player_stats := player.get_player_stats()

	_expect(player_stats != null, "PlayerStats should exist.")
	_expect(hud.reputation_label.text == "Reputation: 0", "HUD should show starting reputation.")
	_expect(hud.heat_label.text == "Heat: 0% - Quiet", "HUD should show starting heat.")
	_expect(save_manager.delete_save(), "Deleting an old test save should succeed.")

	player_stats.set_reputation(17)
	player_stats.set_heat(21)
	_expect(hud.reputation_label.text == "Reputation: 17", "HUD should update reputation through signals.")
	_expect(hud.heat_label.text == "Heat: 21% - Noticed", "HUD should update heat through signals.")

	var save_data: Dictionary = save_manager.build_save_data(main)
	var saved_player_stats: Dictionary = save_data.get("player_stats", {})
	_expect(saved_player_stats.get("reputation", -1) == 17, "Save data should include reputation.")
	_expect(saved_player_stats.get("heat", -1) == 21, "Save data should include heat.")
	_expect(save_manager.save_game(main), "Saving reputation and heat should succeed.")

	player_stats.set_reputation(1)
	player_stats.set_heat(1)
	_expect(save_manager.load_game(main), "Loading reputation and heat should succeed.")
	_expect(player_stats.get_reputation() == 17, "Loading should restore reputation.")
	_expect(player_stats.get_heat() == 21, "Loading should restore heat.")
	_expect(hud.reputation_label.text == "Reputation: 17", "Loading should update HUD reputation.")
	_expect(hud.heat_label.text == "Heat: 21% - Noticed", "Loading should update HUD heat.")

	var old_save_data := save_manager.build_save_data(main)
	old_save_data.erase("player_stats")
	player_stats.set_reputation(9)
	player_stats.set_heat(9)
	_expect(save_manager.apply_save_data(main, old_save_data), "Old saves without player_stats should apply safely.")
	_expect(player_stats.get_reputation() == 9, "Old saves should leave current reputation unchanged.")
	_expect(player_stats.get_heat() == 9, "Old saves should leave current heat unchanged.")

	var invalid_save_data := save_manager.build_save_data(main)
	invalid_save_data["player_stats"] = {"reputation": -100, "heat": 999}
	_expect(save_manager.apply_save_data(main, invalid_save_data), "Out-of-range PlayerStats should load safely.")
	_expect(player_stats.get_reputation() == 0, "Invalid reputation should clamp to zero.")
	_expect(player_stats.get_heat() == 100, "Invalid heat should clamp to 100.")
	_expect(hud.reputation_label.text == "Reputation: 0", "Clamped reputation should update the HUD.")
	_expect(hud.heat_label.text == "Heat: 100% - Lockdown Risk", "Clamped heat should update the HUD.")

	invalid_save_data["player_stats"] = {"reputation": "invalid", "heat": []}
	player_stats.set_reputation(5)
	player_stats.set_heat(5)
	_expect(save_manager.apply_save_data(main, invalid_save_data), "Malformed PlayerStats should load safely.")
	_expect(player_stats.get_reputation() == 0, "Malformed reputation should load as zero.")
	_expect(player_stats.get_heat() == 0, "Malformed heat should load as zero.")
	_expect(hud.heat_label.text == "Heat: 0% - Quiet", "Malformed heat should update the HUD safely.")

	_finish(save_manager)


func _finish(save_manager) -> void:
	if save_manager != null:
		_expect(save_manager.delete_save(), "Deleting the reputation/heat test save should succeed.")

	if _failures.is_empty():
		print("REPUTATION_HEAT_SAVE_HUD_SMOKE_TEST: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("REPUTATION_HEAT_SAVE_HUD_SMOKE_TEST: FAIL")
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
