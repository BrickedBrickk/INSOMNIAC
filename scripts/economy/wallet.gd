class_name Wallet
extends Node

signal money_changed(new_amount: int)

var _money: int = 0


func add_money(amount: int) -> void:
	if amount <= 0:
		return

	_money += amount
	money_changed.emit(_money)
	print("Wallet: $%d" % _money)


func get_money() -> int:
	return _money


func set_money(amount: int) -> void:
	_money = maxi(amount, 0)
	money_changed.emit(_money)
	print("Wallet: $%d" % _money)


func can_afford(amount: int) -> bool:
	return amount >= 0 and _money >= amount


func spend_money(amount: int) -> bool:
	if amount <= 0 or not can_afford(amount):
		return false

	_money -= amount
	money_changed.emit(_money)
	print("Wallet: $%d" % _money)
	return true
