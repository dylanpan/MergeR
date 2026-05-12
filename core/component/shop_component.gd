extends BaseComponent

# ============================================================
# 商店组件（替代 ShopComponent.js）
# ============================================================

class_name ShopComponent

var shop_id: int = 0
var shop_type: int = 0
var items: Array = []
var refresh_count: int = 3

func _init(p_shop_id: int = 0, p_type: int = 0):
	comp_name = "Shop"
	shop_id = p_shop_id
	shop_type = p_type

func add_item(item_data: Dictionary) -> void:
	items.append(item_data)

func remove_item(index: int) -> void:
	if index >= 0 and index < items.size():
		items.remove_at(index)

func refresh(new_items: Array) -> void:
	items = new_items.duplicate()