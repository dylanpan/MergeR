class_name InventoryService

# ============================================================
# 库存服务
# 管理物品和货币
# ============================================================

var _items: Dictionary = {}
var _currencies: Dictionary = {}

func _init():
	pass

# ==================== 物品 ====================

func add_item(item_id: int, count: int = 1) -> void:
	_items[item_id] = _items.get(item_id, 0) + count

func remove_item(item_id: int, count: int = 1) -> void:
	var current = _items.get(item_id, 0)
	if current <= count:
		_items.erase(item_id)
	else:
		_items[item_id] = current - count

func get_item_count(item_id: int) -> int:
	return _items.get(item_id, 0)

func has_item(item_id: int, count: int = 1) -> bool:
	return get_item_count(item_id) >= count

func get_all_items() -> Dictionary:
	return _items.duplicate()

func clear_items() -> void:
	_items.clear()

# ==================== 货币 ====================

func add_currency(currency_id: int, count: int = 1) -> void:
	_currencies[currency_id] = _currencies.get(currency_id, 0) + count

func remove_currency(currency_id: int, count: int = 1) -> void:
	var current = _currencies.get(currency_id, 0)
	if current <= count:
		_currencies.erase(currency_id)
	else:
		_currencies[currency_id] = current - count

func get_currency_count(currency_id: int) -> int:
	return _currencies.get(currency_id, 0)

func has_enough_currency(currency_id: int, value: int) -> bool:
	return get_currency_count(currency_id) >= value

func spend_currency(currency_id: int, value: int) -> bool:
	if not has_enough_currency(currency_id, value):
		return false
	_currencies[currency_id] = _currencies.get(currency_id, 0) - value
	if _currencies[currency_id] <= 0:
		_currencies.erase(currency_id)
	return true

func get_all_currencies() -> Dictionary:
	return _currencies.duplicate()

func clear_currencies() -> void:
	_currencies.clear()

# ==================== 重置 ====================

func reset() -> void:
	_items.clear()
	_currencies.clear()