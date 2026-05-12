extends BaseRestEntity

class_name RestHealCamp

func _init(p_rest_id: int = 80001):
	super(p_rest_id, "heal_camp")

func on_enter() -> Dictionary:
	return {"id": rest_id, "type": rest_type, "name": "治愈营地", "desc": "恢复所有己方单位50%HP"}

func on_confirm() -> void:
	var self_entities = WorldDataManager.get_order_self_entities()
	for entity in self_entities:
		var data_comp = entity.get_component("Data") as DataComponent
		if data_comp:
			var max_hp = data_comp.data.get("maxHp", data_comp.data.get("hp", 100))
			var heal_amount = max_hp * 0.5
			data_comp.data["hp"] = min(data_comp.data.get("hp", 0) + heal_amount, max_hp)

func on_skip() -> void:
	pass