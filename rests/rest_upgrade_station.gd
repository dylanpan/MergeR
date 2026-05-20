extends BaseRestEntity

class_name RestUpgradeStation

var _atk_bonus: int = 3

func _init(p_rest_id: int = 80002):
	super(p_rest_id, "upgrade_station")

func on_init() -> void:
	_atk_bonus = _meta.get("atkBonus", 3)

func get_ui_data() -> Dictionary:
	var data = _meta.duplicate()
	data["name"] = "升级站"
	data["desc"] = "永久提升攻击力+" + str(_atk_bonus)
	return data

func on_confirm() -> void:
	var world = GdRoguelikeManager.get_world()
	if not world:
		return
	var self_entities = world.entity_service.get_order_self()
	for entity in self_entities:
		var data_comp = entity.get_component(ComponentNames.DATA) as DataComponent
		if data_comp:
			data_comp.data["atk"] = data_comp.data.get("atk", 0) + _atk_bonus

func on_enter() -> Dictionary:
	return get_ui_data()
