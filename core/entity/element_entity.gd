extends BaseEntity

# ============================================================
# 元素/棋子实体（替代 ElementEntity.js）
# 支持数据初始化、BuffId配置、存档Buff恢复
# ============================================================

class_name ElementEntity

func get_entity_type() -> int:
	return EntityType.ELEMENT

func _init(i: int = 0, j: int = 0, root = null, area_id: int = 0):
	var coord = CoordComponent.new(i, j, area_id)
	add_component(coord)
	
	var data_comp = DataComponent.new()
	add_component(data_comp)
	
	var buff_comp = BuffComponent.new()
	add_component(buff_comp)
	
	var meta_comp = MetaComponent.new()
	add_component(meta_comp)
	
	var ui_comp = UIComponent.new()
	add_component(ui_comp)

func init(data: Dictionary) -> void:
	"""初始化元素数据，包括BuffId配置和存档Buff恢复"""
	var data_comp = get_component(ComponentNames.DATA) as DataComponent
	if not data_comp or data.is_empty():
		return
	
	data_comp.init(data)
	
	# 初始化配置中的BuffId
	var buff_id = data.get("buffId", 0)
	if buff_id:
		var _world = ClearRoguelikeManager.get_world()
		var buff_config = _world.config_service.get_buff(buff_id) if _world and _world.config_service else {}
		if not buff_config.is_empty():
			var buff_comp = get_component(ComponentNames.BUFF) as BuffComponent
			if buff_comp:
				buff_comp.add_buff({
					"type": buff_config.get("type", ""),
					"value": buff_config.get("value", 0),
					"duration": -1,
					"source": "element_config"
				})
	
	# 从存档恢复临时Buff（若data中包含buffs字段）
	var buffs_data = data.get("buffs", data.get("buff", []))
	if buffs_data and typeof(buffs_data) == TYPE_ARRAY and not buffs_data.is_empty():
		var buff_comp = get_component(ComponentNames.BUFF) as BuffComponent
		if buff_comp and buff_comp.has_method("from_json"):
			buff_comp.from_json(buffs_data)
