class_name EnemyFactory

# ============================================================
# 敌人工厂（从 WorldDataManager 中拆分）
# 负责根据回合配置生成敌方单位数据
# ============================================================

static func create_order_enermy_data(round_meta: Dictionary, modifiers = null, cur_round_idx: int = 0) -> Array:
	var difficulty_config = {}
	if modifiers:
		difficulty_config = {
			"hpMultiplier": modifiers.get("hpMultiplier", 1.0),
			"atkMultiplier": modifiers.get("atkMultiplier", 1.0),
			"stepReduction": modifiers.get("stepReduction", 1.0),
			"dropRate": modifiers.get("dropRate", 1.0),
		}
	else:
		difficulty_config = _get_difficulty_config(round_meta)
	
	var base_step = round_meta.get("baseStep", round_meta.get("step", 30))
	var current_round = cur_round_idx
	var actual_step = max(5, floor(base_step * pow(difficulty_config.get("stepReduction", 1.0), current_round)))
	
	var order_enermy = []
	var order_enermy_ids = round_meta.get("orderEnermyPool", [])
	
	for order_enermy_id in order_enermy_ids:
		var order_enermy_meta = MetaConsts.get("orderEnermy", {}).get(order_enermy_id, {})
		var hp_multiplier = pow(difficulty_config.get("hpMultiplier", 1.0), current_round)
		var atk_multiplier = pow(difficulty_config.get("atkMultiplier", 1.0), current_round)
		
		var drop_items = []
		if order_enermy_meta.get("dropItems"):
			for item in order_enermy_meta["dropItems"]:
				var new_item = item.duplicate()
				new_item["chance"] = min(1.0, item.get("chance", 0.0) * pow(difficulty_config.get("dropRate", 1.0), current_round))
				drop_items.append(new_item)
		
		var order_enermy_data = {
			"id": order_enermy_meta.get("id", 0),
			"hp": floor(order_enermy_meta.get("hp", 100) * hp_multiplier),
			"step": actual_step,
			"type": GameConsts.OrderType_Enermy,
			"isAtker": 0,
			"buff": 0,
			"bullets": [],
			"difficulty": current_round + 1,
			"dropItems": drop_items,
		}
		order_enermy.append(order_enermy_data)
	return order_enermy

static func _get_difficulty_config(round_meta: Dictionary) -> Dictionary:
	var round_id = round_meta.get("id", 0)
	var round_difficulty = MetaConsts.get("roundDifficulty", {}).get(round_id, {})
	var difficulty_type = round_difficulty.get("difficulty", "normal")
	var difficulty_config = MetaConsts.get("difficultyCurves", {}).get(difficulty_type, {})
	return difficulty_config if not difficulty_config.is_empty() else MetaConsts.get("difficultyCurves", {}).get("normal", {})