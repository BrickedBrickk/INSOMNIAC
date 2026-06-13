extends SceneTree

const ORDER_PATHS: PackedStringArray = [
	"res://resources/orders/quiet_night.tres",
	"res://resources/orders/fast_fix.tres",
	"res://resources/orders/penthouse_trial.tres",
	"res://resources/orders/study_break.tres",
	"res://resources/orders/late_shift.tres",
	"res://resources/orders/street_blur.tres",
	"res://resources/orders/afterparty.tres",
	"res://resources/orders/glass_room.tres",
	"res://resources/orders/private_floor.tres",
]

var _failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var order_ids: Dictionary = {}
	for path: String in ORDER_PATHS:
		var order := load(path) as CustomerOrderData
		_expect(order != null, "Order resource should load: %s" % path)
		if order == null:
			continue

		_expect(not order_ids.has(order.id), "Order id should be unique: %s" % order.id)
		order_ids[order.id] = true
		_expect(order.requested_amount > 0, "%s should request at least one item." % order.id)
		_expect(order.payout > 0, "%s should have a positive payout." % order.id)

		var item_path := "res://resources/items/%s.tres" % order.requested_item_id
		var item := load(item_path) as LucidItemData
		_expect(item != null, "%s should request an existing Lucid item." % order.id)
		if item != null:
			_expect(item.id == order.requested_item_id, "%s should reference the loaded Lucid id." % order.id)

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("MORE_ORDERS_CONTENT_SMOKE_TEST: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("MORE_ORDERS_CONTENT_SMOKE_TEST: FAIL")
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
