class_name PlayerStats
extends Node

signal reputation_changed(value: int)
signal heat_changed(value: int)

var reputation: int = 0:
	set(value):
		var clamped_value := maxi(value, 0)
		if reputation == clamped_value:
			return
		reputation = clamped_value
		reputation_changed.emit(reputation)

var heat: int = 0:
	set(value):
		var clamped_value := clampi(value, 0, 100)
		if heat == clamped_value:
			return
		heat = clamped_value
		heat_changed.emit(heat)


func get_reputation() -> int:
	return reputation


func set_reputation(value: int) -> void:
	reputation = value


func add_reputation(amount: int) -> void:
	set_reputation(reputation + amount)


func get_heat() -> int:
	return heat


func set_heat(value: int) -> void:
	heat = value


func add_heat(amount: int) -> void:
	set_heat(heat + amount)


func reduce_heat(amount: int) -> void:
	if amount <= 0:
		return
	set_heat(heat - amount)


func get_heat_level_name() -> String:
	if heat < 20:
		return "Quiet"
	if heat < 40:
		return "Noticed"
	if heat < 60:
		return "Watched"
	if heat < 80:
		return "Targeted"
	return "Lockdown Risk"
