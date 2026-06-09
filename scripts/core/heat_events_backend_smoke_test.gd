extends SceneTree

const HEAT_EVENT_MANAGER_SCRIPT := preload("res://scripts/heat/heat_event_manager.gd")
const PLAYER_STATS_SCRIPT := preload("res://scripts/stats/player_stats.gd")
const SAVE_MANAGER_SCRIPT := preload("res://scripts/save/save_manager.gd")

var _failures: PackedStringArray = []
var _events: Array[Dictionary] = []


class TestWallet:
	extends Node

	var money: int = 0

	func get_money() -> int:
		return money

	func set_money(value: int) -> void:
		money = value


class TestInventory:
	extends Node

	var items: Dictionary = {}

	func get_all_items() -> Dictionary:
		return items.duplicate(true)

	func set_items_from_save(data: Dictionary) -> bool:
		items = data.duplicate(true)
		return true


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_threshold_crossings()
	_test_heat_jump_order()
	_test_save_state()
	_finish()


func _test_threshold_crossings() -> void:
	var stats = PLAYER_STATS_SCRIPT.new()
	var manager = HEAT_EVENT_MANAGER_SCRIPT.new()
	manager.heat_event_triggered.connect(_record_event)
	manager.connect_to_player_stats(stats)

	_expect(_events.is_empty(), "Heat 0 should not trigger an event.")

	stats.set_heat(20)
	_expect(_events.size() == 1, "Crossing heat 20 should trigger exactly once.")
	if _events.size() == 1:
		_expect(_events[0]["name"] == "Noticed", "Heat 20 should trigger Noticed.")
		_expect(_events[0]["message"] == "DPI chatter is picking up.", "Heat 20 should use the expected message.")
		_expect(_events[0]["heat"] == 20, "Heat 20 should report the current heat.")

	stats.set_heat(19)
	stats.set_heat(20)
	_expect(_events.size() == 1, "Re-crossing heat 20 should not retrigger Noticed.")

	stats.set_heat(40)
	_expect(_events.size() == 2, "Crossing heat 40 should trigger exactly one additional event.")
	if _events.size() == 2:
		_expect(_events[1]["name"] == "Watched", "Heat 40 should trigger Watched.")
		_expect(
			_events[1]["message"] == "DPI scanners have been seen nearby.",
			"Heat 40 should use the expected message."
		)

	stats.set_heat(39)
	stats.set_heat(40)
	_expect(_events.size() == 2, "Re-crossing heat 40 should not retrigger Watched.")

	manager.free()
	stats.free()
	_events.clear()


func _test_heat_jump_order() -> void:
	var stats = PLAYER_STATS_SCRIPT.new()
	var manager = HEAT_EVENT_MANAGER_SCRIPT.new()
	manager.heat_event_triggered.connect(_record_event)
	manager.connect_to_player_stats(stats)

	stats.set_heat(65)
	_expect(_events.size() == 3, "A heat jump from 0 to 65 should trigger three events.")
	if _events.size() == 3:
		_expect(
			[_events[0]["name"], _events[1]["name"], _events[2]["name"]] == ["Noticed", "Watched", "Targeted"],
			"A heat jump from 0 to 65 should trigger Noticed, Watched, and Targeted in order."
		)
		_expect(
			_events[2]["message"] == "DPI has started watching this area.",
			"Heat 60 should use the expected message."
		)

	stats.set_heat(10)
	stats.set_heat(65)
	_expect(_events.size() == 3, "Dropping and returning to heat 65 should not spam triggered events.")

	stats.set_heat(80)
	_expect(_events.size() == 4, "Crossing heat 80 should trigger one additional event.")
	if _events.size() == 4:
		_expect(_events[3]["name"] == "Lockdown Risk", "Heat 80 should trigger Lockdown Risk.")
		_expect(
			_events[3]["message"] == "Lockdown risk. Move product before things get worse.",
			"Heat 80 should use the expected message."
		)

	manager.free()
	stats.free()
	_events.clear()


func _test_save_state() -> void:
	var test_root := Node.new()
	test_root.name = "HeatEventsBackendSaveTest"
	root.add_child(test_root)

	var wallet := TestWallet.new()
	var inventory := TestInventory.new()
	var stats = PLAYER_STATS_SCRIPT.new()
	var manager = HEAT_EVENT_MANAGER_SCRIPT.new()
	test_root.add_child(wallet)
	test_root.add_child(inventory)
	test_root.add_child(stats)
	test_root.add_child(manager)
	manager.connect_to_player_stats(stats)

	stats.set_heat(45)
	var save_manager = SAVE_MANAGER_SCRIPT.new()
	var save_data: Dictionary = save_manager.build_save_data(test_root)
	var heat_events_data: Dictionary = save_data.get("heat_events", {})
	_expect(
		heat_events_data.get("triggered_thresholds", []) == [20, 40],
		"Save data should include triggered heat thresholds."
	)

	manager.reset_triggered_events()
	_expect(manager.get_triggered_thresholds_for_save().is_empty(), "Reset should clear triggered heat events.")
	_expect(save_manager.apply_save_data(test_root, save_data), "Heat event save data should load safely.")
	_expect(
		manager.get_triggered_thresholds_for_save() == [20, 40],
		"Loading should restore triggered heat thresholds."
	)

	var old_save_data := save_data.duplicate(true)
	old_save_data.erase("heat_events")
	manager.reset_triggered_events()
	_expect(
		save_manager.apply_save_data(test_root, old_save_data),
		"Old saves without heat_events should load safely."
	)
	_expect(
		manager.get_triggered_thresholds_for_save().is_empty(),
		"Old saves without heat_events should leave current heat event state unchanged."
	)

	test_root.free()


func _record_event(event_name: String, message: String, heat: int) -> void:
	_events.append({
		"name": event_name,
		"message": message,
		"heat": heat,
	})


func _finish() -> void:
	if _failures.is_empty():
		print("HEAT_EVENTS_BACKEND_SMOKE_TEST: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("HEAT_EVENTS_BACKEND_SMOKE_TEST: FAIL")
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
