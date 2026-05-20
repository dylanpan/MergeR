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
	var source_entity = WorldHelper.get_entity_by_id(entity_id)
	if not source_entity:
		return
	
	# 获取所有敌方单位
	var world = GdRoguelikeManager.get_world()
	if not world:
		return
	var enemies = world.entity_service.get_order_enemy()
	
	# 遍历对每个目标执行完整受击流程（含护盾/Buff检查）
	for target in enemies:
		if source_entity.has_method("apply_damage"):
			source_entity.apply_damage(target, damage)
		else:
			# fallback: 直接修改HP
			var data_comp = target.get_component(ComponentNames.DATA) as DataComponent
			if data_comp:
				data_comp.data["hp"] = data_comp.data.get("hp", 0) - damage
	
	var target_count = enemies.size()
	
	# UI攻击特效通知
	GlobalEventBus.event_battle_update.emit({
		"type": "area_attack",
		"entity_id": entity_id,
		"damage": damage,
		"target_count": target_count
	})

# 技能注册
SkillRegistry.register_skill("area_attack", AreaAttackSkill)
