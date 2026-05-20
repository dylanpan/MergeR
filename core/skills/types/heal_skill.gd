extends BaseSkill

# 治疗技能 — 恢复实体生命值
func _init(p_skill_data: Dictionary = {}):
	super(p_skill_data)
	_register_event_listener()

func _register_event_listener() -> void:
	connect_to_bus("event_ui_update_self_hit")

func on_execute(context: Dictionary) -> void:
	var value = skill_data.get("value", 20)
	var heal_percent = context.get("healPercent", 0.0)
	var entity_id = context.get("entityId", "")
	
	# 获取实体
	var target = WorldHelper.get_entity_by_id(entity_id)
	if not target:
		return
	
	var data_comp = target.get_component(ComponentNames.DATA) as DataComponent
	if not data_comp:
		return
	
	var max_hp = data_comp.data.get("maxHp", data_comp.data.get("hp", 100))
	var actual_heal = value
	
	# 计算百分比治疗
	if heal_percent > 0.0:
		actual_heal += floor(max_hp * heal_percent / 100.0)
	
	# 应用治疗 不超过最大HP
	data_comp.data["hp"] = min(max_hp, data_comp.data.get("hp", 0) + actual_heal)
	
	# 治疗效果事件通知 → UI显示治疗数字
	GlobalEventBus.event_battle_update.emit({
		"type": "heal_effect",
		"entity_id": entity_id,
		"amount": actual_heal
	})
	
	# HP更新事件通知 → UI更新血条
	GlobalEventBus.event_battle_update.emit({
		"type": "hp_update",
		"entity_id": entity_id,
		"current_hp": data_comp.data["hp"],
		"max_hp": max_hp
	})

# 技能注册
SkillRegistry.register_skill("heal", HealSkill)
