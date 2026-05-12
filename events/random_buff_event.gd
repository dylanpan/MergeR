extends BaseEventEntity

class_name RandomBuffEvent

func _init(p_event_id: int = 70003):
	super(p_event_id, "random_buff")

func on_enter() -> Dictionary:
	return {"id": event_id, "type": event_type, "name": "随机 Buff", "options": [{"id": 1, "text": "接受祝福"}, {"id": 2, "text": "离开"}]}

func on_option_select(option_id: int) -> void:
	if option_id == 1:
		var buff_types = ["atk_up", "def_up", "shield", "heal"]
		var selected = buff_types[randi() % buff_types.size()]
		var self_entity = WorldDataManager.get_order_self_entity()
		if self_entity:
			BuffSystem.get_instance().add_buff(self_entity, selected, 5.0, 5)