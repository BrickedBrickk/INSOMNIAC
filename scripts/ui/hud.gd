class_name HUD
extends CanvasLayer

@onready var interaction_prompt: Label = $InteractionPrompt
@onready var inventory_debug: Label = $InventoryDebug
@onready var status_message: Label = $StatusMessage
@onready var machine_panel: MachinePanel = $MachinePanel
@onready var money_label: Label = $MoneyLabel
@onready var reputation_label: Label = $ReputationLabel
@onready var heat_label: Label = $HeatLabel

var _inventory: Inventory
var _wallet: Wallet
var _player_stats: Node


func set_inventory(inventory: Inventory) -> void:
	if _inventory != null and _inventory.inventory_changed.is_connected(_update_inventory):
		_inventory.inventory_changed.disconnect(_update_inventory)

	_inventory = inventory
	if _inventory != null:
		_inventory.inventory_changed.connect(_update_inventory)
	_update_inventory()


func set_interaction_prompt(prompt: String) -> void:
	interaction_prompt.text = prompt


func set_wallet(wallet: Wallet) -> void:
	if _wallet != null and _wallet.money_changed.is_connected(_update_money):
		_wallet.money_changed.disconnect(_update_money)

	_wallet = wallet
	if _wallet != null:
		_wallet.money_changed.connect(_update_money)
		_update_money(_wallet.get_money())
	else:
		_update_money(0)


func set_player_stats(player_stats: Node) -> void:
	var reputation_callback := Callable(self, "_update_reputation")
	var heat_callback := Callable(self, "_update_heat")
	if _player_stats != null:
		if _player_stats.has_signal("reputation_changed") and _player_stats.is_connected(
			"reputation_changed",
			reputation_callback
		):
			_player_stats.disconnect("reputation_changed", reputation_callback)
		if _player_stats.has_signal("heat_changed") and _player_stats.is_connected(
			"heat_changed",
			heat_callback
		):
			_player_stats.disconnect("heat_changed", heat_callback)

	_player_stats = player_stats
	if _player_stats != null:
		if _player_stats.has_signal("reputation_changed"):
			_player_stats.connect("reputation_changed", reputation_callback)
		if _player_stats.has_signal("heat_changed"):
			_player_stats.connect("heat_changed", heat_callback)
		_update_reputation(_player_stats.call("get_reputation"))
		_update_heat(_player_stats.call("get_heat"))
	else:
		_update_reputation(0)
		_update_heat(0)


func set_status(message: String) -> void:
	status_message.text = message


func set_machine_panel_data(data: Dictionary) -> void:
	machine_panel.set_panel_data(data)


func _update_inventory() -> void:
	inventory_debug.text = _inventory.get_debug_text() if _inventory != null else "Inventory unavailable"


func _update_money(amount: int) -> void:
	money_label.text = "Money: $%d" % amount


func _update_reputation(amount: Variant) -> void:
	reputation_label.text = "Reputation: %d" % maxi(int(amount), 0)


func _update_heat(amount: Variant) -> void:
	var heat := clampi(int(amount), 0, 100)
	var status := _get_heat_status(heat)
	if _player_stats != null and _player_stats.has_method("get_heat_level_name"):
		status = str(_player_stats.call("get_heat_level_name"))
	heat_label.text = "Heat: %d%% - %s" % [heat, status]


func _get_heat_status(heat: int) -> String:
	if heat < 20:
		return "Quiet"
	if heat < 40:
		return "Noticed"
	if heat < 60:
		return "Watched"
	if heat < 80:
		return "Targeted"
	return "Lockdown Risk"
