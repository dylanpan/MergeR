extends Control
class_name OrderSelfUI

# 己方单位UI（替代 OrderSelfUI.js）

var entity
var _on_click_handler: Callable

func setup(p_entity) -> void:
	entity = p_entity
	_init_event()
	_init_ui()

func set_click_handler(handler: Callable) -> void:
	_on_click_handler = handler

func dispose() -> void:
	queue_free()

func _init_event() -> void:
	# 旧信号（向后兼容）
	GlobalEventBus.event_ui_update_order_self.connect(_on_update_bullet)
	GlobalEventBus.event_ui_update_self_atk.connect(_on_update_bullet)
	GlobalEventBus.event_ui_update_self_hit.connect(_on_update_hp)
	# 新通用信号
	GlobalEventBus.event_battle_update.connect(_on_battle_update)

func _on_battle_update(data: Dictionary) -> void:
	var type = data.get("type", "")
	match type:
		"damage":
			_on_update_hp()
		"self_hit", "self_atk":
			_on_update_bullet()
		"enemy_hit", "enemy_atk":
			pass  # 对方的动作不影响本方

func _on_update_bullet() -> void:
	_init_bullet()

func _on_update_hp() -> void:
	_init_hp()

func _init_ui() -> void:
	_init_role()
	_init_hp()
	_init_weakness()
	_init_bullet()
	_init_btns()

func _init_role() -> void:
	if not has_node("nodeOrder"):
		return
	var node_order = get_node("nodeOrder")
	if node_order.has_node("spRole"):
		var data_comp = entity.get_component(ComponentNames.DATA) if entity.has_method("get_component") else null
		if not data_comp or not data_comp.data:
			return
		var data = data_comp.data
		var meta = MetaConsts.orderSelf.get(data.get("id", 0), {})
		var role_id = meta.get("role", 1)
		var texture_path = "res://assets/roles/order_role_" + str(role_id) + ".png"
		node_order.get_node("spRole").texture = load(texture_path)

func _init_hp() -> void:
	if not has_node("nodeOrder"):
		return
	var node_order = get_node("nodeOrder")
	if node_order.has_node("lbHp") and node_order.get_node("lbHp") is Label:
		var data_comp = entity.get_component(ComponentNames.DATA) if entity.has_method("get_component") else null
		if not data_comp or not data_comp.data:
			return
		var data = data_comp.data
		var meta = MetaConsts.orderSelf.get(data.get("id", 0), {})
		var hp_text = str(data.get("hp", 0)) + "/" + str(meta.get("hp", 0))
		node_order.get_node("lbHp").text = hp_text

func _init_weakness() -> void:
	if not has_node("nodeOrder"):
		return
	var node_order = get_node("nodeOrder")
	if node_order.has_node("nodeWeak"):
		var node_weaks = node_order.get_node("nodeWeak")
		for child in node_weaks.get_children():
			_update_weakness_item(child, null)

func _update_weakness_item(item, data) -> void:
	pass

func _init_bullet() -> void:
	if not has_node("nodeOrder"):
		return
	var node_order = get_node("nodeOrder")
	if node_order.has_node("nodeBullet"):
		var data_comp = entity.get_component(ComponentNames.DATA) if entity.has_method("get_component") else null
		if not data_comp or not data_comp.data:
			return
		var data = data_comp.data
		var bullets = data.get("bullets", [])
		var bullet_nodes = node_order.get_node("nodeBullet")
		for i in range(bullet_nodes.get_child_count()):
			var bullet_node = bullet_nodes.get_child(i)
			if i < bullets.size():
				_update_bullet_item(bullet_node, bullets[i])
			else:
				_update_bullet_item(bullet_node, null)

func _update_bullet_item(item, id) -> void:
	if item is TextureRect:
		if id:
			item.texture = load("res://assets/icons/" + str(id) + ".png")
		else:
			item.texture = null

func _init_btns() -> void:
	if has_node("nodeOrder"):
		var node_order = get_node("nodeOrder")
		if node_order.has_node("btnFinish"):
			node_order.get_node("btnFinish").visible = false

func show_destroy(is_dispose: bool = false) -> void:
	if has_node("nodeOrder"):
		get_node("nodeOrder").visible = false
	if is_dispose:
		dispose()