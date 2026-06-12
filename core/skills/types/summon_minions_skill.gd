extends BaseSkill

# 召唤小怪技能 — 召唤仆从单位
func _init(p_skill_data: Dictionary = {}):
	super(p_skill_data)
	_register_event_listener()

func _register_event_listener() -> void:
	GlobalEventBus.event_battle_update.connect(_on_battle_update)

func _on_battle_update(data: Dictionary) -> void:
	if data.get("type", "") != "enemy_spawn":
		return
	execute({})

func on_execute(context: Dictionary) -> void:
	var count = skill_data.get("count", 1)
	var minion_id = context.get("minionId", skill_data.get("minionId", 30001))
	var minion_hp = context.get("minionHp", 0)
	var entity_id = context.get("entityId", "")
	
	# 获取召唤者实体
	var source_entity = WorldHelper.get_entity_by_id(entity_id)
	if not source_entity:
		return
	
	for i in range(count):
		# 获取小怪配置
		var _world = GdRoguelikeManager.get_world()
		var _config = _world.config_service if _world and _world.config_service else null
		var enermy_meta = _config.get_enemy(minion_id) if _config else {}
		if enermy_meta.is_empty():
			enermy_meta = _config.get_enemy(30001) if _config else {}
		if enermy_meta.is_empty():
			continue
		
		# 创建小怪数据
		var data = {
			"id": enermy_meta.get("id", 0),
			"hp": minion_hp if minion_hp > 0 else enermy_meta.get("hp", 50),
			"def": enermy_meta.get("def", 2),
			"atk": enermy_meta.get("atk", 10),
			"step": enermy_meta.get("step", 5),
			"type": GameConsts.OrderType_Enermy,
			"isAtker": 0,
			"bullets": [],
			"ownerEntityId": entity_id
		}
		
		var entity = OrderEnermyEntity.new(data)
		# 注册实体到entity_manager
		if _world and _world.entity_manager:
			_world.entity_manager.register_entity(entity)
		GlobalEventBus.event_battle_update.emit({"type": "enemy_spawn"})
	
	# UI召唤特效通知
	GlobalEventBus.event_battle_update.emit({
		"type": "summon_effect",
		"entity_id": entity_id,
		"minion_id": minion_id,
		"count": count
	})

# 技能注册
SkillRegistry.register_skill("summon_minions", SummonMinionsSkill)
