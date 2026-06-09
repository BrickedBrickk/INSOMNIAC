extends SceneTree

var _failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_player_stats()
	await _test_quiet_night_rewards()
	_finish()


func _test_player_stats() -> void:
	var stats := PlayerStats.new()

	stats.set_reputation(-10)
	_expect(stats.get_reputation() == 0, "Reputation should clamp to zero.")
	stats.add_reputation(7)
	_expect(stats.get_reputation() == 7, "Reputation should increase.")
	stats.add_reputation(-20)
	_expect(stats.get_reputation() == 0, "Reputation additions should not reduce it below zero.")
	stats.reputation = -1
	_expect(stats.get_reputation() == 0, "Direct reputation assignments should clamp to zero.")

	stats.set_heat(-10)
	_expect(stats.get_heat() == 0, "Heat should clamp to zero.")
	stats.set_heat(150)
	_expect(stats.get_heat() == 100, "Heat should clamp to 100.")
	stats.heat = 101
	_expect(stats.get_heat() == 100, "Direct heat assignments should clamp to 100.")
	stats.reduce_heat(35)
	_expect(stats.get_heat() == 65, "Reducing heat should subtract the requested amount.")
	stats.reduce_heat(-10)
	_expect(stats.get_heat() == 65, "Reducing heat by a negative amount should do nothing.")

	var heat_levels := {
		0: "Quiet",
		19: "Quiet",
		20: "Noticed",
		39: "Noticed",
		40: "Watched",
		59: "Watched",
		60: "Targeted",
		79: "Targeted",
		80: "Lockdown Risk",
		100: "Lockdown Risk",
	}
	for heat_value: int in heat_levels:
		stats.set_heat(heat_value)
		_expect(
			stats.get_heat_level_name() == heat_levels[heat_value],
			"Heat %d should be %s." % [heat_value, heat_levels[heat_value]]
		)

	stats.free()


func _test_quiet_night_rewards() -> void:
	var board_scene: PackedScene = load("res://scenes/world/CustomerOrderBoard.tscn")
	var player_scene: PackedScene = load("res://scenes/player/PlayerDesktopRig.tscn")
	_expect(board_scene != null, "CustomerOrderBoard scene should load.")
	_expect(player_scene != null, "Player scene should load.")
	if board_scene == null or player_scene == null:
		return

	var test_root := Node.new()
	root.add_child(test_root)

	var board := board_scene.instantiate() as CustomerOrderBoard
	var player := player_scene.instantiate() as PlayerDesktopRig
	test_root.add_child(board)
	test_root.add_child(player)
	await process_frame

	var inventory := player.get_inventory()
	var wallet := player.get_wallet()
	var stats := player.get_player_stats()
	_expect(stats != null, "PlayerDesktopRig should provide PlayerStats.")
	_expect(player.get_node_or_null("PlayerStats") == stats, "PlayerStats should be a child of PlayerDesktopRig.")
	if stats == null:
		test_root.queue_free()
		return

	inventory.add_item("beach_loop", "Beach Loop", 2)
	var starting_money := wallet.get_money()
	board.interact(player)
	_expect(wallet.get_money() == starting_money + 40, "Quiet Night should pay $40.")
	_expect(stats.get_reputation() == 2, "Quiet Night should add reputation +2.")
	_expect(stats.get_heat() == 1, "Quiet Night should add heat +1.")

	board.set_selected_order_index(0)
	var money_before_repeat := wallet.get_money()
	var reputation_before_repeat := stats.get_reputation()
	var heat_before_repeat := stats.get_heat()
	var items_before_repeat := inventory.get_amount("beach_loop")
	board.interact(player)
	_expect(wallet.get_money() == money_before_repeat, "Re-completing Quiet Night should not pay again.")
	_expect(
		stats.get_reputation() == reputation_before_repeat,
		"Re-completing Quiet Night should not add reputation again."
	)
	_expect(stats.get_heat() == heat_before_repeat, "Re-completing Quiet Night should not add heat again.")
	_expect(
		inventory.get_amount("beach_loop") == items_before_repeat,
		"Re-completing Quiet Night should not consume items again."
	)

	test_root.queue_free()


func _finish() -> void:
	if _failures.is_empty():
		print("REPUTATION_HEAT_STATS_SMOKE_TEST: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("REPUTATION_HEAT_STATS_SMOKE_TEST: FAIL")
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
