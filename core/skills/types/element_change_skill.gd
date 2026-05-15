extends BaseSkill

# 元素变化技能 — 切换实体攻击元素类型
func _init(p_skill_data: Dictionary = {}):
	super(p_skill_data)
	_register_event_listener()

func _register_event_listener() -> void:
	connect_to_bus("event_ui_update_self_atk")

func on_execute(context: Dictionary) -> void:
	var element_type = context.get("elementType", skill_data.get("element", randi() % 4 + 1))
	var duration = context.get("duration", 3)
	var entity_id = context.get("entityId", "")
	
	# 获取实体
	var target = WorldHelper.get_entity_by_id(entity_id)
	if not target:
		return
	
	var elem_change = target.get_component(ComponentNames.ELEMENT_CHANGE) as ElementChangeComponent
	if elem_change:
		elem_change.change_to(element_type, duration)
	
	# UI视觉效果通知
	GlobalEventBus.event_ui_update_self_atk.emit()