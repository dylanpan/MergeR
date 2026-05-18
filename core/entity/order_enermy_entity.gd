extends BaseEntity

# ============================================================
# 敌方单位实体（替代 OrderEnermyEntity.js）
# 支持普通敌人和Boss（含阶段/技能/护盾/元素变化系统）
# ============================================================

class_name OrderEnermyEntity

func get_entity_type() -> int:
	return EntityType.ORDER_ENEMY

var step: int = 0

func _init(data: Dictionary = {}):
	var data_comp = DataComponent.new(data)
	add_component(data_comp)
	
	var buff_comp = BuffComponent.new()
	add_component(buff_comp)
	
	step = data.get("step", 0)
	
	# 若是Boss则初始化Boss组件
	if is_boss():
		_init_boss_components(data)

func init(data: Dictionary) -> void:
	"""初始化敌人数据，包括配置中的BuffId和Boss能力"""
	var data_comp = get_component(ComponentNames.DATA) as DataComponent
	if not data_comp or data.is_empty():
		return
	
	data_comp.init(data)
	
	# 初始化配置中的BuffId
	var buff_id = data.get("buffId", 0)
	if buff_id:
		_init_buff_from_config(buff_id)
	
	# 若是Boss初始化Boss能力
	if is_boss():
		_init_boss_abilities(data)

func _init_buff_from_config(buff_id: int) -> void:
	"""从MetaConsts读取并应用固有Buff"""
	var buff_data = MetaConsts.buffs.get(buff_id, {})
	if buff_data.is_empty():
		return
	
	var buff_comp = get_component(ComponentNames.BUFF) as BuffComponent
	if not buff_comp:
		return
	
	buff_comp.add_buff({
		"type": buff_data.get("type", ""),
		"value": buff_data.get("value", 0),
		"duration": -1,
		"source": "enemy_config"
	})

func _init_boss_components(data: Dictionary) -> void:
	"""初始化Boss特殊组件"""
	var skill_comp = SkillComponent.new()
	add_component(skill_comp)
	
	var shield_comp = ShieldComponent.new()
	add_component(shield_comp)
	
	# 初始化护盾
	shield_comp.init({"entityId": -1})

func _init_boss_abilities(data: Dictionary) -> void:
	"""初始化Boss阶段管理、技能、元素变化等能力"""
	var phases = data.get("phases", [])
	if phases.is_empty():
		return
	
	# 初始化阶段管理器
	var phase_manager = PhaseManagerComponent.new()
	add_component(phase_manager)
	phase_manager.init(phases, -1)
	
	# 初始化技能管理器
	var skill_comp = get_component(ComponentNames.SKILL) as SkillComponent
	if skill_comp and skill_comp.has_method("init"):
		var current_phase = phase_manager.get_current_phase()
		if current_phase and current_phase.has("config"):
			skill_comp.init(current_phase.config.get("skills", []), -1)

func is_boss() -> bool:
	"""判断是否为Boss（data中有phases字段）"""
	var data_comp = get_component(ComponentNames.DATA) as DataComponent
	if not data_comp:
		return false
	var data = data_comp.data
	return data.has("phases") and data.get("phases", []).size() > 0

func apply_damage(target_entity, damage: int) -> void:
	"""对目标实体应用伤害（含护盾检查）"""
	if not target_entity:
		return
	
	var data_comp = target_entity.get_component(ComponentNames.DATA) as DataComponent
	if not data_comp:
		return
	
	var data = data_comp.data
	
	# 检查护盾
	var shield_comp = target_entity.get_component(ComponentNames.SHIELD) as ShieldComponent
	if shield_comp and shield_comp.is_active:
		var absorbed = shield_comp.take_damage(damage)
		if absorbed <= 0:
			return  # 伤害被护盾完全吸收
		damage = absorbed
	
	# 应用剩余伤害
	var hp = data.get("hp", 0)
	data["hp"] = max(0, hp - damage)

func get_hp() -> int:
	var data_comp = get_component(ComponentNames.DATA) as DataComponent
	return data_comp.data.get("hp", 0) if data_comp else 0

func set_hp(value: int) -> void:
	var data_comp = get_component(ComponentNames.DATA) as DataComponent
	if data_comp:
		data_comp.data["hp"] = value

func reduce_hp(amount: int) -> void:
	var data_comp = get_component(ComponentNames.DATA) as DataComponent
	if data_comp:
		var hp = data_comp.data.get("hp", 0)
		data_comp.data["hp"] = max(0, hp - amount)

func is_alive() -> bool:
	return get_hp() > 0

func reduce_step() -> void:
	if step > 0:
		step -= 1

func is_step_zero() -> bool:
	return step <= 0
