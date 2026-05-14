extends BaseEntity

# ============================================================
# 元素/棋子实体（替代 ElementEntity.js）
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
	var data_comp = get_component(ComponentNames.DATA) as DataComponent
	if data_comp and not data.is_empty():
		data_comp.init(data)
		var buff_id = data.get("buffId", 0)
		if buff_id:
			var buff_config = MetaConsts.buffs.get(buff_id, {})
			if not buff_config.is_empty():
				var buff_comp = get_component(ComponentNames.BUFF) as BuffComponent
				if buff_comp:
					buff_comp.add_buff({
						"type": buff_config.get("type", ""),
						"value": buff_config.get("value", 0),
						"duration": -1,
						"source": "element_config"
					})
