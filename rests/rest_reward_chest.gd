extends BaseRestEntity

class_name RestRewardChest

var _reward_items: Array = []

func _init(p_rest_id: int = 80003):
	super(p_rest_id, "reward_chest")

func on_init() -> void:
	# 读取配置中的奖励池
	_reward_items = _meta.get("rewardPool", [])
	if _reward_items.is_empty():
		_reward_items = [{"itemId": 60000001, "count": 1, "weight": 1}]

func get_ui_data() -> Dictionary:
	var data = _meta.duplicate()
	data["name"] = "奖励宝箱"
	data["desc"] = "获得随机道具"
	return data

func on_confirm() -> void:
	var world = ClearRoguelikeManager.get_world()
	if not world:
		return
	
	# 加权随机选择奖励
	var items = []
	var weights = []
	for r in _reward_items:
		var item_id = r.get("itemId", 60000001)
		items.append(item_id)
		weights.append(r.get("weight", 1))
	
	if items.is_empty():
		return
	
	var total_weight = 0.0
	for w in weights:
		total_weight += w
	
	var roll = randf() * total_weight
	var selected_id = items[-1]
	for i in range(items.size()):
		roll -= weights[i]
		if roll <= 0:
			selected_id = items[i]
			break
	
	var count = 1
	if not _reward_items.is_empty():
		count = _reward_items[items.find(selected_id)].get("count", 1)
	
	world.inventory_service.add_item(selected_id, count)

func on_enter() -> Dictionary:
	return get_ui_data()
