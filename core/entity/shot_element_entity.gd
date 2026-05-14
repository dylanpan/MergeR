extends BaseEntity

# ============================================================
# 攻击位/按钮实体（替代 ShotElementEntity.js）
# ============================================================

class_name ShotElementEntity

func get_entity_type() -> int:
	return EntityType.SHOT

func _init(data: Dictionary = {}):
	var data_comp = DataComponent.new(data)
	add_component(data_comp)
	
	var buff_comp = BuffComponent.new()
	add_component(buff_comp)