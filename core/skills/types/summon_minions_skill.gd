extends BaseSkill

# 召唤小怪技能 — 召唤仆从单位
func _init(p_skill_data: Dictionary = {}):
	super(p_skill_data)
	_register_event_listener()

func _register_event_listener() -> void:
	connect_to_bus("event_on_enemy_spawn")

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
		var enermy_meta = MetaConsts.orderEnermy.get(minion_id, MetaConsts.orderEnermy.get(30001, {}))
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
		WorldHelper.register_entity(entity)
		GlobalEventBus.event_on_enemy_spawn.emit(entity)
