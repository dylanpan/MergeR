extends Node

# ============================================================
# 休息点工厂（替代 RestFactory.js）
# 负责根据 rest_id 创建休息点实体，并注入元数据配置
# ============================================================

static func create_rest_entity(rest_id: int, meta: Dictionary = {}) -> BaseRestEntity:
	var entity: BaseRestEntity
	match rest_id:
		80001:
			entity = RestHealCamp.new(rest_id)
		80002:
			entity = RestUpgradeStation.new(rest_id)
		80003:
			entity = RestRewardChest.new(rest_id)
		_:
			return null
	
	# 注入元数据配置：若未提供 meta，从 MetaConsts 自动读取
	if meta.is_empty() and MetaConsts.has("gameRests"):
		meta = MetaConsts.get("gameRests", {}).get(rest_id, {})
	
	entity.init(meta)
	return entity
