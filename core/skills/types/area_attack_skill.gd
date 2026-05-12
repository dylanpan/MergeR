extends BaseSkill

# 范围攻击技能 — 对全场目标造成伤害
func _init(p_skill_data: Dictionary = {}):
	super(p_skill_data)
	_register_event_listener()

func _register_event_listener() -> void:
	connect_to_bus("event_ui_update_enermy_hit")

func on_execute(context: Dictionary) -> void:
	var damage = skill_data.get("value", 10)
	var entity_id = context.get("entityId", "")
	
	# 获取攻击者实体
	var source_entity = WorldDataManager.get_entity_by_id(entity_id)
	if not source_entity:
		return
	
	# 获取所有敌方单位
	var enemies = WorldDataManager.get_order_enermy_entities()
	
	# 遍历对每个目标执行伤害
	for target in enemies:
		var data_comp = target.get_component("Data") as DataComponent
		if data_comp:
			data_comp.data["hp"] = data_comp.data.get("hp", 0) - damage
	
	# UI攻击特效通知
	GlobalEventBus.event_ui_update_enermy_hit.emit()