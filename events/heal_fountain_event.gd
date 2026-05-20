extends BaseEventEntity

class_name HealFountainEvent

var _heal_amount: int = 0  # 预计算的治疗量

func _init(p_event_id: int = 70002):
	super(p_event_id, "heal_fountain")

# 初始化时从配置读取 healPercent 预计算治疗量
func on_init() -> void:
	var heal_percent = _meta.get("healPercent", 0.5)  # 默认50%
	var world = GdRoguelikeManager.get_world()
	if not world:
		_heal_amount = 30  # fallback
		return
	
	var self_entities = world.entity_service.get_order_self()
	var max_hp = 100
	for entity in self_entities:
		var data_comp = entity.get_component(ComponentNames.DATA) as DataComponent
		if data_comp:
			max_hp = max(max_hp, data_comp.data.get("maxHp", data_comp.data.get("hp", 100)))
	
	_heal_amount = int(floor(float(max_hp) * heal_percent))

# 打开时返回 UI 数据（含治疗量预览）
func get_ui_data() -> Dictionary:
	var data = _meta.duplicate()
	data["name"] = "治愈喷泉"
	data["healAmount"] = _heal_amount
	data["options"] = [{"id": 1, "text": "恢复HP"}, {"id": 2, "text": "离开"}]
	return data

# 选项选择回调
func on_option_select(option_id: int) -> void:
	if option_id == 1:
		_heal_player()

# 治疗所有己方单位
func _heal_player() -> void:
	if _heal_amount <= 0:
		return
	
	var world = GdRoguelikeManager.get_world()
	if not world:
		return
	
	var self_entities = world.entity_service.get_order_self()
	for entity in self_entities:
		var data_comp = entity.get_component(ComponentNames.DATA) as DataComponent
		if data_comp:
			var max_hp = data_comp.data.get("maxHp", data_comp.data.get("hp", 100))
			var current_hp = data_comp.data.get("hp", 0)
			data_comp.data["hp"] = min(current_hp + _heal_amount, max_hp)

# 兼容旧接口
func on_enter() -> Dictionary:
	return get_ui_data()
