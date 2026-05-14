extends Control
class_name ShopUI

# 商店UI（替代 ShopUI.js）
# 管理商店面板显示、购买、刷新、关闭交互
# 使用方式：
#   var ui = preload("res://ui/components/shop_ui.tscn").instantiate()
#   parent.add_child(ui)
#   ui.init()

var _current_shop_entity = null
var _is_shop_open: bool = false

func init() -> void:
	if has_node("nodeBtnClose"):
		get_node("nodeBtnClose").pressed.connect(_on_close_click)
	_bind_events()

func _bind_events() -> void:
	GlobalEventBus.event_shop_open.connect(_on_shop_open)

func _on_shop_open(args: Dictionary) -> void:
	var shop_id = args.get("shopId", 0)
	var shop_data = args.get("shopData", {})
	
	# 创建商店实体
	_current_shop_entity = ShopEntity.new(shop_id, self)
	_current_shop_entity.init(shop_data)
	
	# 显示商店UI
	_show_shop_ui()

func _show_shop_ui() -> void:
	if not _current_shop_entity:
		return
	visible = true
	_is_shop_open = true
	_update_item_slots()
	_update_gold_display()

func _update_item_slots() -> void:
	if not _current_shop_entity or not has_node("itemSlots"):
		return
	
	var shop_comp = _current_shop_entity.get_component(ComponentNames.SHOP) if _current_shop_entity.has_method("get_component") else null
	if not shop_comp:
		return
	
	var item_slots = get_node("itemSlots")
	for i in range(item_slots.get_child_count()):
		var slot = item_slots.get_child(i)
		var item_id = shop_comp.get_item_id(i)
		if item_id:
			var item_meta = MetaConsts.get("shopItems", {}).get(item_id, {})
			if slot.has_node("lblName"):
				slot.get_node("lblName").text = item_meta.get("name", "")
			if slot.has_node("lblPrice"):
				slot.get_node("lblPrice").text = str(item_meta.get("price", 0)) + "金币"
			if slot.has_node("lblDesc"):
				slot.get_node("lblDesc").text = item_meta.get("desc", "")
			slot.visible = true
		else:
			slot.visible = false

func _update_gold_display() -> void:
	if has_node("lblGold"):
		var player_gold = WorldDataManager.get_currency_count(1)  # 假设货币ID=1是金币
		get_node("lblGold").text = "金币: " + str(player_gold)

func _on_item_buy(index: int) -> void:
	if not _current_shop_entity:
		return
	
	var shop_system = ShopSystem.new()
	var success = shop_system.purchase_item(_current_shop_entity, index)
	if success:
		_update_item_slots()
		_update_gold_display()
		GlobalEventBus.event_shop_buy.emit(0, index)
	else:
		# 购买失败：显示提示信息
		if has_node("lblFeedback"):
			get_node("lblFeedback").text = "金币不足或商品已售罄！"
			get_node("lblFeedback").visible = true
			# 启动计时器自动隐藏提示
			var timer = get_tree().create_timer(2.0)
			timer.timeout.connect(func(): 
				if has_node("lblFeedback"):
					get_node("lblFeedback").visible = false
			)
		else:
			push_warning("ShopUI: 购买失败，index=" + str(index))

func _on_refresh_click() -> void:
	if not _current_shop_entity:
		return
	
	var shop_system = ShopSystem.new()
	var success = shop_system.refresh_shop(_current_shop_entity)
	if success:
		_update_item_slots()
		GlobalEventBus.event_shop_refresh.emit([], 0)

func _on_close_click() -> void:
	_hide_shop_ui()

func _hide_shop_ui() -> void:
	visible = false
	_is_shop_open = false
	_current_shop_entity = null
	GlobalEventBus.event_shop_close.emit()

func dispose() -> void:
	_current_shop_entity = null
	queue_free()