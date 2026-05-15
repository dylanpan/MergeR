extends BaseEventEntity

class_name TreasureChestEvent

func _init(p_event_id: int = 70001):
	super(p_event_id, "treasure_chest")

func on_enter() -> Dictionary:
	return {"id": event_id, "type": event_type, "name": "宝箱", "options": [{"id": 1, "text": "打开宝箱"}, {"id": 2, "text": "离开"}]}

func on_option_select(option_id: int) -> void:
	if option_id == 1:
		var world = ClearRoguelikeManager.get_world()
		if world:
			world.inventory_service.add_item(60000001, randi() % 3 + 1)
