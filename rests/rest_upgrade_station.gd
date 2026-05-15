extends BaseRestEntity

class_name RestUpgradeStation

func _init(p_rest_id: int = 80002):
	super(p_rest_id, "upgrade_station")

func on_enter() -> Dictionary:
	return {"id": rest_id, "type": rest_type, "name": "升级站", "desc": "永久提升攻击力+3"}

func on_confirm() -> void:
	var world = ClearRoguelikeManager.get_world()
	var self_entity = world.entity_service.get_order_self_entity() if world else null
	if self_entity:
		var data_comp = self_entity.get_component(ComponentNames.DATA) as DataComponent
		if data_comp:
			data_comp.data["atk"] = data_comp.data.get("atk", 0) + 3

func on_skip() -> void:
	pass