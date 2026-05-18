extends BaseRestEntity

class_name RestHealCamp

var _heal_percent: float = 0.5

func _init(p_rest_id: int = 80001):
	super(p_rest_id, "heal_camp")

func on_init() -> void:
	_heal_percent = _meta.get("healPercent", 0.5)

func get_ui_data() -> Dictionary:
	var data = _meta.duplicate()
	data["name"] = "治愈营地"
	data["desc"] = "恢复所有己方单位" + str(int(_heal_percent * 100)) + "%HP"
	return data

func on_confirm() -> void:
	var world = ClearRoguelikeManager.get_world()
	if not world:
		return
	var self_entities = world.entity_service.get_order_self()
	for entity in self_entities:
		var data_comp = entity.get_component(ComponentNames.DATA) as DataComponent
		if data_comp:
			var max_hp = data_comp.data.get("maxHp", data_comp.data.get("hp", 100))
			var heal_amount = int(floor(float(max_hp) * _heal_percent))
			data_comp.data["hp"] = min(data_comp.data.get("hp", 0) + heal_amount, max_hp)

func on_enter() -> Dictionary:
	return get_ui_data()
