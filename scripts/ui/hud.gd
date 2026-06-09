class_name HUD
extends CanvasLayer

@onready var interaction_prompt: Label = $InteractionPrompt
@onready var inventory_debug: Label = $InventoryDebug
@onready var status_message: Label = $StatusMessage
@onready var machine_panel: MachinePanel = $MachinePanel
@onready var money_label: Label = $MoneyLabel

var _inventory: Inventory
var _wallet: Wallet


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


func set_status(message: String) -> void:
	status_message.text = message


func set_machine_panel_data(data: Dictionary) -> void:
	machine_panel.set_panel_data(data)


func _update_inventory() -> void:
	inventory_debug.text = _inventory.get_debug_text() if _inventory != null else "Inventory unavailable"


func _update_money(amount: int) -> void:
	money_label.text = "Money: $%d" % amount
