extends BaseEventEntity

class_name RandomBuffEvent

var _selected_buff: Dictionary = {}  # 预抽取的 buff

func _init(p_event_id: int = 70003):
	super(p_event_id, "random_buff")

# 初始化时从配置池中预抽取 buff
func on_init() -> void:
	_roll_buff()

# 打开时返回 UI 数据（含 buff 预览）
func get_ui_data() -> Dictionary:
	var data = _meta.duplicate()
	data["name"] = "随机 Buff"
	data["selectedBuff"] = _selected_buff
	data["options"] = [{"id": 1, "text": "接受祝福"}, {"id": 2, "text": "离开"}]
	return data

# 选项选择回调
func on_option_select(option_id: int) -> void:
	if option_id == 1:
		_apply_buff()

# 从配置池中加权随机抽取 buff
func _roll_buff() -> void:
	var buff_pool = _meta.get("buffPool", [])
	if buff_pool.is_empty():
		# fallback 默认 buff
		_selected_buff = {"buffId": "atk_up", "value": 5.0, "duration": 5}
		return
	
	# 加权随机抽取
	var total_chance = 0.0
	for b in buff_pool:
		total_chance += b.get("chance", 0.0)
	
	if total_chance <= 0:
		_selected_buff = buff_pool[0]
		return
	
	var roll = randf() * total_chance
	for b in buff_pool:
		roll -= b.get("chance", 0.0)
		if roll <= 0:
			_selected_buff = b
			return
	
	_selected_buff = buff_pool[-1]

# 给所有己方单位应用 buff
func _apply_buff() -> void:
	if _selected_buff.is_empty():
		return
	
	var world = GdRoguelikeManager.get_world()
	if not world:
		return
	
	var self_entities = world.entity_service.get_order_self()
	var buff_id = _selected_buff.get("buffId", "atk_up")
	var value = _selected_buff.get("value", 5.0)
	var duration = _selected_buff.get("duration", 5)
	
	for entity in self_entities:
		BuffSystem.get_instance().add_buff(entity, buff_id, value, duration, "event_random_buff")

# 兼容旧接口
func on_enter() -> Dictionary:
	return get_ui_data()
