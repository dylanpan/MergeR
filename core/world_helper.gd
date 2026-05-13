extends Node

# ============================================================
# 世界工具类（替代 WorldHelper.js）
# 提供通用的辅助方法集合，简化游戏逻辑调用
# ============================================================

class_name WorldHelper

# 根据实体ID获取实体
static func get_entity_by_id(entity_id: String):
	return WorldDataManager.get_entity_by_id(entity_id)

# 获取当前回合进度
static func get_round_progress() -> float:
	var progress = WorldDataManager.get_step_progress()
	return progress.get("progress", 0.0)

# 检查游戏是否结束
static func is_game_over() -> bool:
	var wdm = WorldDataManager
	return not wdm.has_alive_self()

# 获取管理器中的系统
static func get_systems() -> Array:
	return ClearRoguelikeManager.get_systems()

# ============================================
# 新增：补齐原 WorldHelper.js 的全部静态方法
# ============================================

# 根据实体ID从MetaConsts获取配置
static func get_meta(type_name: String, id: int):
	if not MetaConsts.get(type_name, {}).has(id):
		return null
	return MetaConsts.get(type_name, {}).get(id, null)

# 检查实体是否存活
static func is_alive(entity) -> bool:
	if not entity:
		return false
	if entity.has_method("get_component"):
		var data_comp = entity.get_component(ComponentNames.DATA) as DataComponent
		if data_comp and data_comp.data:
			return data_comp.data.get("hp", 0) > 0
	return false

# 检查订单是否为敌方
static func is_enemy(entity) -> bool:
	if not entity:
		return false
	if entity.has_method("get_component"):
		var data_comp = entity.get_component(ComponentNames.DATA) as DataComponent
		if data_comp and data_comp.data:
			return data_comp.data.get("type", 0) == 2
	return false

# 获取实体当前生命值
static func get_hp(entity) -> int:
	if not entity:
		return 0
	if entity.has_method("get_component"):
		var data_comp = entity.get_component(ComponentNames.DATA) as DataComponent
		if data_comp and data_comp.data:
			return data_comp.data.get("hp", 0)
	return 0

# 获取实体当前生命值百分比 (0~1)
static func get_hp_percent(entity) -> float:
	if not entity:
		return 0.0
	if entity.has_method("get_component"):
		var data_comp = entity.get_component(ComponentNames.DATA) as DataComponent
		if data_comp and data_comp.data:
			var data = data_comp.data
			var hp = data.get("hp", 0)
			var meta_id = data.get("id", 0)
			var max_hp = data.get("maxHp", hp)
			if max_hp <= 0:
				max_hp = 1
			# 尝试从 MetaConsts 获取最大血量
			var order_meta = MetaConsts.get("orderEnermy", {}).get(meta_id, {})
			if order_meta.get("hp", 0) > 0:
				max_hp = order_meta["hp"]
			return clamp(float(hp) / float(max_hp), 0.0, 1.0)
	return 0.0

# 获取实体防御值
static func get_def(entity) -> int:
	if not entity:
		return 0
	if entity.has_method("get_component"):
		var data_comp = entity.get_component(ComponentNames.DATA) as DataComponent
		if data_comp and data_comp.data:
			return data_comp.data.get("def", 0)
	return 0

# 获取实体攻击力
static func get_atk(entity) -> int:
	if not entity:
		return 0
	if entity.has_method("get_component"):
		var data_comp = entity.get_component(ComponentNames.DATA) as DataComponent
		if data_comp and data_comp.data:
			return data_comp.data.get("atk", 0)
	return 0

# 获取当前己方单位数量
static func get_ally_count() -> int:
	return WorldDataManager.get_order_self_entities().size()

# 获取当前敌方单位数量
static func get_enemy_count() -> int:
	return WorldDataManager.get_order_enermy_entities().size()

# 获取当前步数进度百分比 (0~1)
static func get_step_progress_percent() -> float:
	var progress = WorldDataManager.get_step_progress()
	return progress.get("progress", 0.0)

# 在当前所有敌方中随机选择一个
static func get_random_enemy():
	var enemies = WorldDataManager.get_order_enermy_entities()
	if enemies.is_empty():
		return null
	var idx = randi() % enemies.size()
	return enemies[idx]

# 获取当前关卡名称
static func get_level_name() -> String:
	var level = WorldDataManager.get_cur_level()
	return "第 " + str(level + 1) + " 关"

# 难度辅助
static func get_difficulty_name(difficulty: int) -> String:
	match difficulty:
		1:
			return "简单"
		2, 3:
			return "普通"
		4, 5, 6:
			return "困难"
		7, 8, 9, 10:
			return "专家"
		_:
			return "普通"

# 清理所有引用（类级别无需清理，保留用于接口一致性）
static func dispose() -> void:
	pass