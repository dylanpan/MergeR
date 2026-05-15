extends BaseSkill

# 护盾技能 — 为实体添加护盾效果
func _init(p_skill_data: Dictionary = {}):
	super(p_skill_data)
	_register_event_listener()

func _register_event_listener() -> void:
	connect_to_bus("event_ui_update_shield_absorb")

func on_execute(context: Dictionary) -> void:
	var value = skill_data.get("value", 25)
	var duration = context.get("duration", 1)
	var entity_id = context.get("entityId", "")
	
	# 获取实体
	var target = WorldHelper.get_entity_by_id(entity_id)
	if not target:
		return
	
	var shield_comp = target.get_component(ComponentNames.SHIELD) as ShieldComponent
	if shield_comp:
		shield_comp.add_shield(value, duration)
	
	# UI更新通知
	GlobalEventBus.event_ui_update_shield_absorb.emit(entity_id)