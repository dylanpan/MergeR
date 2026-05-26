extends BaseSystem
class_name ShopSystem

# ============================================================
# 商店系统（替代 ShopSystem.js）
# 管理商店的打开、购买、刷新
# ============================================================

func _init():
	pass

func dispose():
	pass

func update(dt: float) -> void:
	pass

func open_shop(entity) -> void:
	if not entity:
		return
	var shop_comp = entity.get_component(ComponentNames.SHOP) as ShopComponent
	if not shop_comp:
		return
	var shop_data = {
		"shopId": shop_comp.shop_id,
		"shopType": shop_comp.shop_type,
		"items": shop_comp.items.duplicate(),
	}
	GlobalEventBus.event_shop_open.emit(shop_comp.shop_id, shop_data)

func buy_item(entity, item_index: int) -> bool:
	var shop_comp = entity.get_component(ComponentNames.SHOP) as ShopComponent
	if not shop_comp:
		return false
	if item_index < 0 or item_index >= shop_comp.items.size():
		return false
	var item = shop_comp.items[item_index]
	shop_comp.remove_item(item_index)
	GlobalEventBus.event_shop_buy.emit(item.get("id", 0), item_index)
	return true

func refresh_shop(entity) -> bool:
	if not entity:
		return false
	var shop_comp = entity.get_component(ComponentNames.SHOP) as ShopComponent
	if not shop_comp:
		return false
	shop_comp.refresh([])
	GlobalEventBus.event_shop_refresh.emit(shop_comp.items, shop_comp.refresh_count)
	return true

func close_shop() -> void:
	GlobalEventBus.event_shop_close.emit()