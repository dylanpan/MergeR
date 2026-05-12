extends Control
class_name OrderEnermyUI

# 敌方单位UI（替代 OrderEnermyUI.js）
# 管理敌方单位的角色图片、血量、步数、子弹、弱点显示
# 使用方式：
#   var ui = preload("res://ui/components/order_enermy_ui.tscn").instantiate()
#   parent.add_child(ui)
#   ui.setup(entity)

var entity

func setup(p_entity) -> void:
	entity = p_entity
	_init_event()
	_init_ui()

func dispose() -> void:
	queue_free()

func _init_event() -> void:
	GlobalEventBus.event_ui_update_enermy_atk.connect(_on_update_bullet)
	GlobalEventBus.event_ui_update_enermy_hit.connect(_on_update_hp)
	GlobalEventBus.event_update_by_step.connect(_on_update_step)
	GlobalEventBus.event_ui_update_enermy_reload.connect(_on_update_bullet)
	GlobalEventBus.event_ui_update_step.connect(_on_update_step_display)
	GlobalEventBus.event_ui_update_refresh_warning.connect(_on_show_refresh_warning)

func _on_update_bullet() -> void:
	_init_bullet()
	_init_step()

func _on_update_hp() -> void:
	_init_hp()

func _on_update_step() -> void:
	_init_step()

func _on_update_step_display(step_data: Dictionary) -> void:
	_update_step_display(step_data)

func _on_show_refresh_warning(warning_data: Dictionary) -> void:
	_show_refresh_warning(warning_data)

func _init_ui() -> void:
	_init_role()
	_init_hp()
	_init_step()
	_init_weakness()
	_init_bullet()
	_init_btns()
	_init_step_display()

func _init_role() -> void:
	if not has_node("nodeOrder"):
		return
	var node_order = get_node("nodeOrder")
	if node_order.has_node("spRole"):
		var data_comp = entity.get_component("Data") if entity.has_method("get_component") else null
		if not data_comp or not data_comp.data:
			return
		var data = data_comp.data
		var meta = MetaConsts.get("orderEnermy", {}).get(data.get("id", 0), {})
		var role_id = meta.get("role", 1)
		var level = meta.get("level", 1)
		
		# 根据等级选择背景
		var bg_idx = 2
		if level <= 5:
			bg_idx = 2
		elif level <= 8:
			bg_idx = 3
		elif level <= 15:
			bg_idx = 4
		
		var texture_path = "res://assets/roles/order_role_" + str(role_id) + ".png"
		node_order.get_node("spRole").texture = load(texture_path)

func _init_hp() -> void:
	if not has_node("nodeOrder"):
		return
	var node_order = get_node("nodeOrder")
	if node_order.has_node("lbHp") and node_order.get_node("lbHp") is Label:
		var data_comp = entity.get_component("Data") if entity.has_method("get_component") else null
		if not data_comp or not data_comp.data:
			return
		var data = data_comp.data
		var meta = MetaConsts.get("orderEnermy", {}).get(data.get("id", 0), {})
		var hp_text = str(data.get("hp", 0)) + "/" + str(meta.get("hp", 0))
		node_order.get_node("lbHp").text = hp_text

func _init_step() -> void:
	if not has_node("nodeOrder"):
		return
	var node_order = get_node("nodeOrder")
	if node_order.has_node("lbStep") and node_order.get_node("lbStep") is Label:
		var data_comp = entity.get_component("Data") if entity.has_method("get_component") else null
		if not data_comp or not data_comp.data:
			return
		var data = data_comp.data
		node_order.get_node("lbStep").text = str(data.get("step", 0))

func _init_weakness() -> void:
	if not has_node("nodeOrder"):
		return
	var node_order = get_node("nodeOrder")
	if node_order.has_node("nodeWeak"):
		var node_weaks = node_order.get_node("nodeWeak")
		for child in node_weaks.get_children():
			_update_weakness_item(child, null)

func _update_weakness_item(item, data) -> void:
	if not item:
		return
	if data == null:
		item.visible = false
		return
	item.visible = true
	
	var element_type = data.get("elementType", 0)
	if item.has_method("set_element_type"):
		item.set_element_type(element_type)
	
	var weakness_map = {
		1: Color(1, 0.3, 0.3), # 火 -> 红
		2: Color(0.3, 0.5, 1), # 水 -> 蓝
		3: Color(0.3, 1, 0.3), # 风 -> 绿
		4: Color(0.8, 0.6, 0.3), # 土 -> 棕
	}
	var color = weakness_map.get(element_type, Color(0.8, 0.8, 0.8))
	if item is TextureRect:
		item.modulate = color
	elif item.has_node("spIcon"):
		item.get_node("spIcon").modulate = color

func _init_bullet() -> void:
	if not has_node("nodeOrder"):
		return
	var node_order = get_node("nodeOrder")
	if node_order.has_node("nodeBullet"):
		var data_comp = entity.get_component("Data") if entity.has_method("get_component") else null
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

func _init_step_display() -> void:
	if has_node("nodeStep"):
		var node_step = get_node("nodeStep")
		node_step.visible = true
		if node_step.has_node("lbStep"):
			node_step.get_node("lbStep").text = "0/0"
		if node_step.has_node("pbStep"):
			node_step.get_node("pbStep").value = 0.0
		if node_step.has_node("lbWarning"):
			node_step.get_node("lbWarning").visible = false

func _update_step_display(step_data: Dictionary) -> void:
	if not has_node("nodeStep"):
		return
	var node_step = get_node("nodeStep")
	if node_step.has_node("lbStep"):
		var step_text = str(step_data.get("current", 0)) + "/" + str(step_data.get("max", 0))
		node_step.get_node("lbStep").text = step_text
	if node_step.has_node("pbStep"):
		node_step.get_node("pbStep").value = step_data.get("progress", 0.0)
	if node_step.has_node("lbWarning"):
		node_step.get_node("lbWarning").visible = false

func _show_refresh_warning(warning_data: Dictionary) -> void:
	if not has_node("nodeStep"):
		return
	var node_step = get_node("nodeStep")
	if node_step.has_node("lbWarning"):
		node_step.get_node("lbWarning").text = warning_data.get("message", "")
		node_step.get_node("lbWarning").visible = true
		_play_warning_animation()

func _play_warning_animation() -> void:
	if not has_node("nodeStep"):
		return
	var node_step = get_node("nodeStep")
	if node_step.has_node("lbWarning"):
		var warning_label = node_step.get_node("lbWarning")
		var tween = create_tween()
		tween.set_loops(3)
		tween.tween_property(warning_label, "modulate:a", 0.0, 0.2)
		tween.tween_property(warning_label, "modulate:a", 1.0, 0.2)

func show_destroy(is_dispose: bool = false) -> void:
	if has_node("nodeOrder"):
		get_node("nodeOrder").visible = false
	if is_dispose:
		dispose()