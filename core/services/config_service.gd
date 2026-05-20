class_name ConfigService

# ============================================================
# 配置服务（替代 MetaConsts.get("xxx", {}).get(id, {}) 直接调用的模式）
# 所有配置访问通过此服务集中管理
#
# 预留可能：
# 加入缓存层（比如把 MetaConsts 数据按需加载）
# 加入配置热更新（运行时替换配置）
# 加入数据监控/统计
# ============================================================

static var _instance: ConfigService = ConfigService.new()
static func instance() -> ConfigService:
	return _instance

# ==============================================
# 直接集合访问（返回完整字典）
# ==============================================

func get_element_weakness() -> Dictionary:
	return MetaConsts.elementWeakness

func get_element_damage_multiplier_map() -> Dictionary:
	return MetaConsts.elementDamageMultiplier

func get_difficulty_curves() -> Dictionary:
	return MetaConsts.difficultyCurves

func get_round_difficulty() -> Dictionary:
	return MetaConsts.roundDifficulty

func get_step_soft_landing() -> Dictionary:
	return MetaConsts.stepSoftLanding

func get_order_self_map() -> Dictionary:
	return MetaConsts.orderSelf

func get_order_enermy_map() -> Dictionary:
	return MetaConsts.orderEnermy

func get_launchers_map() -> Dictionary:
	return MetaConsts.launchers

func get_elements_map() -> Dictionary:
	return MetaConsts.elements

func get_buffs_map() -> Dictionary:
	return MetaConsts.buffs

func get_skills_map() -> Dictionary:
	return MetaConsts.skills

func get_shop_items_map() -> Dictionary:
	return MetaConsts.shopItems

func get_game_shops_map() -> Dictionary:
	return MetaConsts.gameShops

func get_game_events_map() -> Dictionary:
	return MetaConsts.gameEvents

func get_game_rests_map() -> Dictionary:
	return MetaConsts.gameRests

func get_game_levels_map() -> Dictionary:
	return MetaConsts.gameLevels

func get_game_rounds_map() -> Dictionary:
	return MetaConsts.gameRounds

func get_game_start_level_map() -> Dictionary:
	return MetaConsts.gameStartLevel

func get_difficulty_profiles_map() -> Dictionary:
	return MetaConsts.difficultyProfiles

func get_items_map() -> Dictionary:
	return MetaConsts.items

# ==============================================
# 单一实体获取
# ==============================================

func get_enemy(enemy_id: int) -> Dictionary:
	return MetaConsts.orderEnermy.get(enemy_id, {})

func get_self(self_id: int) -> Dictionary:
	return MetaConsts.orderSelf.get(self_id, {})

func get_element(element_id: int) -> Dictionary:
	return MetaConsts.elements.get(element_id, {})

func get_launcher(launcher_id: int) -> Dictionary:
	return MetaConsts.launchers.get(launcher_id, {})

func get_buff(buff_id: int) -> Dictionary:
	return MetaConsts.buffs.get(buff_id, {})

func get_skill(skill_id: int) -> Dictionary:
	return MetaConsts.skills.get(skill_id, {})

func get_shop_item(item_id: int) -> Dictionary:
	return MetaConsts.shopItems.get(item_id, {})

func get_game_shop(shop_id: int) -> Dictionary:
	return MetaConsts.gameShops.get(shop_id, {})

func get_game_event(event_id: int) -> Dictionary:
	return MetaConsts.gameEvents.get(event_id, {})

func get_game_rest(rest_id: int) -> Dictionary:
	return MetaConsts.gameRests.get(rest_id, {})

func get_game_level(level_id: int) -> Dictionary:
	return MetaConsts.gameLevels.get(level_id, {})

func get_game_round(round_id: int) -> Dictionary:
	return MetaConsts.gameRounds.get(round_id, {})

# ==============================================
# 业务方法
# ==============================================

func get_difficulty_profile(difficulty: int) -> Dictionary:
	var level = clampi(difficulty, 1, 10)
	var profile = MetaConsts.difficultyProfiles.get(level, {})
	if profile.is_empty():
		return MetaConsts.difficultyCurves.get("normal", {})
	
	var curve_name = profile.get("curve", "normal")
	var base_curve = MetaConsts.difficultyCurves.get(curve_name, MetaConsts.difficultyCurves.get("normal", {}))
	var cf = profile.get("curveFactor", 1.0)
	
	return {
		"level": level,
		"name": profile.get("name", ""),
		"layerCount": profile.get("layerCount", 14),
		"shopRate": profile.get("shopRate", 0.26),
		"eliteRate": profile.get("eliteRate", 0.20),
		"eventRate": profile.get("eventRate", 0.20),
		"restRate": profile.get("restRate", 0.16),
		"bossFrequency": profile.get("bossFrequency", 6),
		"stepReduction": 1.0 - (1.0 - base_curve.get("stepReduction", 0.94)) * cf,
		"hpMultiplier": 1.0 + (base_curve.get("hpMultiplier", 1.12) - 1.0) * cf,
		"atkMultiplier": 1.0 + (base_curve.get("atkMultiplier", 1.06) - 1.0) * cf,
		"dropRate": 1.0 + (base_curve.get("dropRate", 1.05) - 1.0) * cf,
		"minStep": maxf(base_curve.get("minStep", 14) * cf, 3),
		"maxHpMultiplier": base_curve.get("maxHpMultiplier", 3.0) * cf,
		"maxAtkMultiplier": base_curve.get("maxAtkMultiplier", 2.2) * cf,
		"smoothingStart": base_curve.get("smoothingStart", 7),
		"smoothingFactor": base_curve.get("smoothingFactor", 0.75),
	}

func get_difficulty_config(round_id: int) -> Dictionary:
	var rd = MetaConsts.roundDifficulty.get(round_id, {})
	if rd.is_empty():
		return MetaConsts.difficultyCurves.get("normal", {})
	var diff_type = rd.get("difficulty", "normal")
	return MetaConsts.difficultyCurves.get(diff_type, MetaConsts.difficultyCurves.get("normal", {}))

func get_difficulty_config_by_type(difficulty_type: String) -> Dictionary:
	return MetaConsts.difficultyCurves.get(difficulty_type, MetaConsts.difficultyCurves.get("normal", {}))

func resolve_enemy(enemy_id: int, override: Dictionary = {}) -> Dictionary:
	var base = get_enemy(enemy_id)
	if base.is_empty():
		return {}
	var result = base.duplicate(true)
	for key in override:
		result[key] = override[key]
	return result

func resolve_buff(buff_id: int, override: Dictionary = {}) -> Dictionary:
	var base = get_buff(buff_id)
	if base.is_empty():
		return {}
	var result = base.duplicate(true)
	if override and not override.is_empty():
		if not result.has("bonus"):
			result["bonus"] = {}
		for key in override:
			if result.has(key):
				result[key] = override[key]
		result["bonus"] = result.get("bonus", {}).duplicate()
		for key in override:
			result["bonus"][key] = override[key]
	return result

func resolve_skill(skill_id: int, override: Dictionary = {}) -> Dictionary:
	var base = get_skill(skill_id)
	if base.is_empty():
		return {}
	var result = base.duplicate(true)
	for key in override:
		result[key] = override[key]
	return result

# ==============================================
# 元素系统辅助方法
# ==============================================

func get_weakness_multiplier(atk_elem: int, def_elem: int) -> float:
	var elem_mult = MetaConsts.elementDamageMultiplier.get(atk_elem, {})
	return elem_mult.get(def_elem, 1.0)

func is_weakness(atk_elem: int, def_elem: int) -> bool:
	return MetaConsts.elementWeakness.get(atk_elem, -1) == def_elem

func is_resistance(atk_elem: int, def_elem: int) -> bool:
	return MetaConsts.elementWeakness.get(def_elem, -1) == atk_elem

func get_element_damage_multiplier(atk_elem: int, def_elem: int) -> float:
	return get_weakness_multiplier(atk_elem, def_elem)

func get_element_merge_output(element_id: int) -> int:
	var meta = get_element(element_id)
	return meta.get("mergeId", 0)

func round_to_floor(value: float) -> float:
	return floor(value)

# ==============================================
# GameConsts 常量访问
# ==============================================

func get_stage_none() -> int: return GameConsts.StageNone
func get_stage_init() -> int: return GameConsts.StageInit
func get_stage_pre_battle() -> int: return GameConsts.StagePreBattle
func get_stage_self_battle() -> int: return GameConsts.StageSelfBattle
func get_stage_enermy_battle() -> int: return GameConsts.StageEnermyBattle
func get_stage_end_self_battle() -> int: return GameConsts.StageEndSelfBattle
func get_stage_end_enermy_battle() -> int: return GameConsts.StageEndEnermyBattle
func get_stage_shop() -> int: return GameConsts.StageShop

func get_round_state_normal() -> int: return GameConsts.RoundState_Normal
func get_round_state_game_start() -> int: return GameConsts.RoundState_GameStart
func get_round_state_game_over() -> int: return GameConsts.RoundState_GameOver
func get_round_state_round_over() -> int: return GameConsts.RoundState_RoundOver
func get_round_state_max_step() -> int: return GameConsts.RoundState_MaxStep
func get_round_state_level_over() -> int: return GameConsts.RoundState_LevelOver

func get_order_type_self() -> int: return GameConsts.OrderType_Self
func get_order_type_enermy() -> int: return GameConsts.OrderType_Enermy

func get_map_node_type() -> Dictionary: return GameConsts.MapNodeType
func get_entity_type_name() -> Dictionary: return GameConsts.EntityTypeName
func get_boss_round_id() -> Dictionary: return GameConsts.BossRoundId

func get_area_id_element() -> int: return GameConsts.AreaId_Element
func get_area_id_launcher() -> int: return GameConsts.AreaId_Launcher
func get_area_id_bullet() -> int: return GameConsts.AreaId_Bullet
func get_area_id_shot() -> int: return GameConsts.AreaId_Shot