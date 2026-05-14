extends BaseEntity

# ============================================================
# 发射器实体（替代 LauncherEntity.js）
# ============================================================

class_name LauncherEntity

func get_entity_type() -> int:
	return EntityType.LAUNCHER

func _init(i: int = 0, j: int = 0, root = null, area_id: int = 1):
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
	
	var launcher_comp = LauncherComponent.new()
	add_component(launcher_comp)