extends BaseRestEntity

class_name RestRewardChest

func _init(p_rest_id: int = 80003):
	super(p_rest_id, "reward_chest")

func on_enter() -> Dictionary:
	return {"id": rest_id, "type": rest_type, "name": "奖励宝箱", "desc": "获得随机道具"}

func on_confirm() -> void:
	var item_ids = [60000001, 60000002, 60000003, 60000004]
	var selected = item_ids[randi() % item_ids.size()]
	var world = ClearRoguelikeManager.get_world()
	if world:
		world.inventory_service.add_item(selected, 1)

func on_skip() -> void:
	pass