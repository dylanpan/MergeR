extends BaseEventEntity

class_name TreasureChestEvent

var _reward: Dictionary = {}  # 预抽取的奖励

func _init(p_event_id: int = 70001):
	super(p_event_id, "treasure_chest")

# 初始化时从配置池中预抽取奖励
func on_init() -> void:
	_roll_reward()

# 打开时返回 UI 数据（含奖励预览）
func get_ui_data() -> Dictionary:
	var data = _meta.duplicate()
	data["name"] = "宝箱"
	data["options"] = [{"id": 1, "text": "打开宝箱"}, {"id": 2, "text": "离开"}]
	if not _reward.is_empty():
		data["rewardPreview"] = _reward
	return data

# 选项选择回调
func on_option_select(option_id: int) -> void:
	if option_id == 1:
		_give_reward()

# 从配置池中加权随机抽取奖励
func _roll_reward() -> void:
	var reward_pool = _meta.get("rewardPool", [])
	if reward_pool.is_empty():
		# fallback 固定奖励
		_reward = {"itemId": 60000001, "count": 1}
		return
	
	# 加权随机抽取
	var total_chance = 0.0
	for r in reward_pool:
		total_chance += r.get("chance", 0.0)
	
	if total_chance <= 0:
		_reward = reward_pool[0]
		return
	
	var roll = randf() * total_chance
	for r in reward_pool:
		roll -= r.get("chance", 0.0)
		if roll <= 0:
			_reward = r
			return
	
	_reward = reward_pool[-1]

# 发放奖励
func _give_reward() -> void:
	if _reward.is_empty():
		return
	
	var world = GdRoguelikeManager.get_world()
	if not world:
		return
	
	var item_id = _reward.get("itemId", 60000001)
	var count = _reward.get("count", 1)
	world.inventory_service.add_item(item_id, count)
	_reward = {}  # 防止重复发放

# 兼容旧接口
func on_enter() -> Dictionary:
	return get_ui_data()
