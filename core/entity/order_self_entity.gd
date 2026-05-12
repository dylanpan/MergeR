extends BaseEntity

# ============================================================
# 己方单位实体（替代 OrderSelfEntity.js）
# ============================================================

class_name OrderSelfEntity

func _init(data: Dictionary = {}):
	var data_comp = DataComponent.new(data)
	add_component(data_comp)
	
	var buff_comp = BuffComponent.new()
	add_component(buff_comp)

func get_hp() -> int:
	var data_comp = get_component("Data") as DataComponent
	return data_comp.data.get("hp", 0) if data_comp else 0

func set_hp(value: int) -> void:
	var data_comp = get_component("Data") as DataComponent
	if data_comp:
		data_comp.data["hp"] = value

func reduce_hp(amount: int) -> void:
	var data_comp = get_component("Data") as DataComponent
	if data_comp:
		var hp = data_comp.data.get("hp", 0)
		data_comp.data["hp"] = max(0, hp - amount)

func is_alive() -> bool:
	return get_hp() > 0