extends BaseEventEntity

class_name HealFountainEvent

func _init(p_event_id: int = 70002):
	super(p_event_id, "heal_fountain")

func on_enter() -> Dictionary:
	return {"id": event_id, "type": event_type, "name": "治愈喷泉", "options": [{"id": 1, "text": "恢复HP"}, {"id": 2, "text": "离开"}]}

func on_option_select(option_id: int) -> void:
	if option_id == 1:
		var self_entities = WorldDataManager.get_order_self_entities()
		for entity in self_entities:
			var data_comp = entity.get_component(ComponentNames.DATA) as DataComponent
			if data_comp:
				var max_hp = data_comp.data.get("maxHp", data_comp.data.get("hp", 100))
				data_comp.data["hp"] = min(data_comp.data.get("hp", 0) + 30, max_hp)