extends BaseSystem
class_name CountDownStepSystem

# ============================================================
# 倒计时步数系统（替代 CountDownStepSystem.js）
# 检测敌方步数归零，触发装弹/攻击
# ============================================================

func _init():
	pass

func dispose():
	pass

func update(dt: float) -> void:
	_update_order_enermy_entities()

func _update_order_enermy_entities() -> void:
	if not _world:
		return
	var order_enermy = _world.entity_service.get_order_enemy()
	for entity in order_enermy:
		var data_comp = entity.get_component(ComponentNames.DATA) as DataComponent
		if not data_comp:
			continue
		var data = data_comp.data
		if data.get("step", 1) <= 0 and not data.get("isPreAtker", false):
			if data.get("bullets", []).is_empty():
				# 装弹 - 恢复至原始步数
				var origin_meta = _world.config_service.get_enemy(data.get("id", 0))
				data["step"] = origin_meta.get("step", 30)
				var bullets = origin_meta.get("bullets", [])
				data["bullets"] = data.get("bullets", []) + bullets
				GlobalEventBus.event_battle_update.emit({"type": "reload"})
			else:
				# 发起攻击
				data["isAtker"] = 1
				_world.game_state_service.add_stage(GameConsts.StageEnermyBattle)