extends BaseEntity

# ============================================================
# 敌方单位实体（替代 OrderEnermyEntity.js）
# ============================================================

class_name OrderEnermyEntity

func get_entity_type() -> int:
	return EntityType.ORDER_ENEMY

var step: int = 0

func _init(data: Dictionary = {}):
	var data_comp = DataComponent.new(data)
	add_component(data_comp)
	
	var buff_comp = BuffComponent.new()
	add_component(buff_comp)
	
	step = data.get("step", 0)

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

func reduce_step() -> void:
	if step > 0:
		step -= 1

func is_step_zero() -> bool:
	return step <= 0