extends Node

# ============================================================
# 程序化地图生成器（替代 MapGenerator.js）
# 基于难度配置与MetaConsts池生成可复现的关卡序列
# ============================================================

class_name MapGenerator

static func generate_game_rounds(profile: Dictionary, prng: Prng) -> Dictionary:
	var game_rounds = {}
	var round_id = 50001
	
	for tier in range(1, 16):
		var diff_setting = MetaConsts.roundDifficulty.get(50000 + tier, {})
		var step_reduction = pow(profile.get("stepReduction", 1.0), tier - 1)
		var base_step = diff_setting.get("baseStep", 20) * step_reduction
		
		# 步数软着陆保护
		var soft_landing = MetaConsts.stepSoftLanding
		if base_step < soft_landing.get("criticalThreshold", 10):
			base_step = max(soft_landing.get("minGuaranteedStep", 3),
				base_step + soft_landing.get("emergencyBonus", 3) * (1.0 - tier / 15.0) * soft_landing.get("recoveryRate", 0.5))
		
		var enemy_pool = []
		var enemy_count = min(1 + floor(tier / 3), 4)
		
		var allowed_types = []
		var difficulty_str = diff_setting.get("difficulty", "normal")
		match difficulty_str:
			"normal":
				allowed_types = ["normal"]
			"hard":
				allowed_types = ["normal", "elite"]
			"expert":
				allowed_types = ["elite", "boss"]
		
		var all_enemies = []
		for enemy_id in MetaConsts.orderEnermy.keys():
			var enemy = MetaConsts.orderEnermy[enemy_id]
			if allowed_types.has(enemy.get("type", "")):
				all_enemies.append(enemy)
		
		for i in range(enemy_count):
			var target_tier_min = max(1, tier - 3 + i)
			var target_tier_max = min(6, tier + i)
			var candidates = []
			for enemy in all_enemies:
				var e_tier = enemy.get("tier", 1)
				if e_tier >= target_tier_min and e_tier <= target_tier_max:
					candidates.append(enemy)
			if not candidates.is_empty():
				var selected_idx = prng.next_int(0, candidates.size() - 1)
				if selected_idx >= 0 and selected_idx < candidates.size():
					enemy_pool.append(candidates[selected_idx].get("id", 30001))
		
		var round_data = {
			"id": round_id,
			"step": max(int(ceil(base_step)), 5),
			"baseStep": diff_setting.get("baseStep", 20),
			"orderEnermyPool": enemy_pool,
			"tier": tier,
			"difficulty": difficulty_str,
		}
		game_rounds[round_id] = round_data
		round_id += 1
	
	return game_rounds

static func generate_map(difficulty: int, seed: int) -> MapModel:
	var prng = Prng.new(seed)
	var profile = MetaConsts.get_difficulty_profile(difficulty)
	var map = MapModel.create_empty_map(difficulty, seed)
	
	# 生成 game rounds
	map.game_rounds = generate_game_rounds(profile, prng)
	
	var round_ids = map.game_rounds.keys()
	round_ids.sort()
	
	var layer_id = 1
	for i in range(round_ids.size()):
		var round_id = round_ids[i]
		var round_data = map.game_rounds[round_id]
		var tier = round_data.get("tier", 1)
		
		var node_type = "battle"
		if tier >= 14:
			node_type = "boss"
		elif tier >= 10 and tier % 2 == 0:
			node_type = "elite"
		elif tier >= 5 and prng.next_float() < 0.3:
			node_type = "shop"
		elif prng.next_float() < 0.2:
			node_type = "rest"
		elif prng.next_float() < 0.15:
			node_type = "event"
		
		var layer_node = {
			"id": layer_id,
			"type": node_type,
			"roundId": round_id,
			"index": i,
		}
		map.layers.append(layer_node)
		layer_id += 1
	
	# 确保首节点为战斗，末节点为Boss
	if not map.layers.is_empty():
		map.layers[0]["type"] = "battle"
		map.layers[-1]["type"] = "boss"
	
	return map