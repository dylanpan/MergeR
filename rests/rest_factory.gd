extends Node

# ============================================================
# 休息点工厂（替代 RestFactory.js）
# ============================================================

static func create_rest_entity(rest_id: int) -> BaseRestEntity:
	match rest_id:
		80001:
			return RestHealCamp.new(rest_id)
		80002:
			return RestUpgradeStation.new(rest_id)
		80003:
			return RestRewardChest.new(rest_id)
		_:
			return null