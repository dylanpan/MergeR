extends BaseEntity

# ============================================================
# 攻击位/按钮实体（替代 ShotElementEntity.js）
# 支持坐标管理、UI交互、攻击流程启动
# ============================================================

class_name ShotElementEntity

func get_entity_type() -> int:
	return EntityType.SHOT

func _init(data: Dictionary = {}):
	var data_comp = DataComponent.new(data)
	add_component(data_comp)
	
	var buff_comp = BuffComponent.new()
	add_component(buff_comp)
	
	var coord = CoordComponent.new(data.get("i", 0), data.get("j", 0), data.get("areaId", 0))
	add_component(coord)
	
	var ui_comp = UIComponent.new()
	add_component(ui_comp)

func init(data: Dictionary) -> void:
	"""初始化攻击位数据"""
	var data_comp = get_component(ComponentNames.DATA) as DataComponent
	if data_comp and not data.is_empty():
		data_comp.init(data)
	
	# UI初始化（由外部UI管理器设置）
	var ui_comp = get_component(ComponentNames.UI) as UIComponent
	if ui_comp:
		pass  # UI初始化交由外部调用者处理

func update_data(new_data) -> void:
	"""更新攻击位数据"""
	var data_comp = get_component(ComponentNames.DATA) as DataComponent
	if data_comp:
		data_comp.data = new_data if typeof(new_data) == TYPE_DICTIONARY else {}

func click_attack() -> void:
	"""
	点击攻击位的核心逻辑（简化版，保留关键流程）：
	收集子弹 → 标记攻击者 → 触发战斗阶段
	"""
	var world = ClearRoguelikeManager.get_world()
	if not world:
		return
	
	# 获取己方单位
	var self_entities = world.get_order_self_entities() if world.has_method("get_order_self_entities") else []
	if self_entities.is_empty():
		# fallback: 通过entity_service获取
		self_entities = world.entity_service.get_order_self() if world.has_method("entity_service") else []
	
	if self_entities.is_empty():
		return
	
	# 标记第一个己方单位为攻击者
	var first_self = self_entities[0]
	var data_comp = first_self.get_component(ComponentNames.DATA) as DataComponent
	if data_comp:
		data_comp.data["isAtker"] = 1
	
	# 触发战斗阶段
	if world.has_method("start_battle_phase"):
		world.start_battle_phase()
