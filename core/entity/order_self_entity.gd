extends BaseEntity

# ============================================================
# 己方单位实体（替代 OrderSelfEntity.js）
# 支持数据初始化、BuffId配置、UI显示与点击交互
# ============================================================

class_name OrderSelfEntity

func get_entity_type() -> int:
	return EntityType.ORDER_SELF

func _init(data: Dictionary = {}):
	var data_comp = DataComponent.new(data)
	add_component(data_comp)
	
	var buff_comp = BuffComponent.new()
	add_component(buff_comp)

func init(data: Dictionary) -> void:
	"""初始化角色数据，包括配置中的BuffId"""
	var data_comp = get_component(ComponentNames.DATA) as DataComponent
	if not data_comp or data.is_empty():
		return
	
	data_comp.init(data)
	
	# 初始化配置中的BuffId
	var buff_id = data.get("buffId", 0)
	if buff_id:
		var _world = ClearRoguelikeManager.get_world()
		var buff_data = _world.config_service.get_buff(buff_id) if _world and _world.config_service else {}
		if not buff_data.is_empty():
			var buff_comp = get_component(ComponentNames.BUFF) as BuffComponent
			if buff_comp:
				buff_comp.add_buff({
					"type": buff_data.get("type", ""),
					"value": buff_data.get("value", 0),
					"duration": -1,
					"source": "order_self_config"
				})

func get_hp() -> int:
	var data_comp = get_component(ComponentNames.DATA) as DataComponent
	return data_comp.data.get("hp", 0) if data_comp else 0

func set_hp(value: int) -> void:
	var data_comp = get_component(ComponentNames.DATA) as DataComponent
	if data_comp:
		data_comp.data["hp"] = value

func reduce_hp(amount: int) -> void:
	var data_comp = get_component(ComponentNames.DATA) as DataComponent
	if data_comp:
		var hp = data_comp.data.get("hp", 0)
		data_comp.data["hp"] = max(0, hp - amount)

func is_alive() -> bool:
	return get_hp() > 0
