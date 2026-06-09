class_name HeatEventManager
extends Node

signal heat_event_triggered(event_name: String, message: String, heat: int)

const THRESHOLDS: Array[int] = [20, 40, 60, 80]
const EVENTS: Dictionary = {
	20: {
		"name": "Noticed",
		"message": "DPI chatter is picking up.",
	},
	40: {
		"name": "Watched",
		"message": "DPI scanners have been seen nearby.",
	},
	60: {
		"name": "Targeted",
		"message": "DPI has started watching this area.",
	},
	80: {
		"name": "Lockdown Risk",
		"message": "Lockdown risk. Move product before things get worse.",
	},
}

var _player_stats: Node
var _triggered_thresholds: Dictionary = {}


func connect_to_player_stats(player_stats) -> void:
	if _player_stats != null and _player_stats.is_connected("heat_changed", handle_heat_changed):
		_player_stats.disconnect("heat_changed", handle_heat_changed)

	_player_stats = player_stats if player_stats is Node else null
	if _player_stats == null:
		return
	if not _player_stats.has_signal("heat_changed"):
		push_warning("HeatEventManager: PlayerStats does not expose heat_changed.")
		_player_stats = null
		return

	_player_stats.connect("heat_changed", handle_heat_changed)
	if _player_stats.has_method("get_heat"):
		handle_heat_changed(int(_player_stats.call("get_heat")))


func handle_heat_changed(heat: int) -> void:
	for threshold: int in THRESHOLDS:
		if heat < threshold or _triggered_thresholds.has(threshold):
			continue
		_triggered_thresholds[threshold] = true
		var event_data: Dictionary = EVENTS[threshold]
		heat_event_triggered.emit(
			str(event_data["name"]),
			str(event_data["message"]),
			heat
		)


func get_triggered_thresholds_for_save() -> Array:
	var triggered: Array = []
	for threshold: int in THRESHOLDS:
		if _triggered_thresholds.has(threshold):
			triggered.append(threshold)
	return triggered


func load_triggered_thresholds_from_save(data: Array) -> void:
	_triggered_thresholds.clear()
	for value: Variant in data:
		if not _is_number(value):
			continue
		var threshold := int(value)
		if THRESHOLDS.has(threshold):
			_triggered_thresholds[threshold] = true


func reset_triggered_events() -> void:
	_triggered_thresholds.clear()


func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
