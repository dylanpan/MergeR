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
		
		# 加权选敌（与JS版10/3权重一致）
		for i in range(enemy_count):
			var target_tier_min = max(1, tier - 3 + i)
			var target_tier_max = min(6, tier + i)
			
			var candidates = []   # enemy objects
			var weights = []      # corresponding weights
			for enemy in all_enemies:
				var e_tier = enemy.get("tier", 1)
				var weight = 1
				if e_tier >= target_tier_min and e_tier <= target_tier_max:
					weight = 10
				elif e_tier >= target_tier_min - 1 and e_tier <= target_tier_max + 1:
					weight = 3
				candidates.append(enemy)
				weights.append(weight)
			
			if not candidates.is_empty():
				var selected = prng.weighted_random_choice(candidates, weights)
				if selected != null:
					enemy_pool.append(selected.get("id", 30001))
		
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

static func generate_game_levels(profile: Dictionary, game_rounds: Dictionary, prng: Prng) -> Dictionary:
	var game_levels = {}
	var level_id = 40001
	var round_ids = game_rounds.keys()
	round_ids.sort()
	
	# 分层节点布局
	var layer_nodes = []
	var total_layers = profile.get("layerCount", 7)
	
	# 第一层 固定1个节点
	layer_nodes.append(1)
	
	# 中间层: 每层2-5个随机节点
	for layer_idx in range(2, total_layers):
		var node_count = 2 + floor(prng.next_float() * 4)  # 2~5
		layer_nodes.append(node_count)
	
	# 最后一层 固定1个节点 (BOSS)
	layer_nodes.append(1)
	
	# 按层生成所有节点
	var layers = []
	for layer_idx in range(layer_nodes.size()):
		var current_layer = []
		var node_count = layer_nodes[layer_idx]
		var progress = float(layer_idx + 1) / float(layer_nodes.size())
		
		for n in range(node_count):
			var round_count = 1 + floor(progress * 3)
			var rounds = []
			
			var min_round = max(1, floor(progress * float(round_ids.size() - 3)))
			var max_round = min(round_ids.size(), min_round + 4)
			
			for ri in range(round_count):
				var round_index = min_round + floor(prng.next_float() * float(max_round - min_round))
				rounds.append(round_ids[min(round_index, round_ids.size() - 1)])
			
			# 节点类型互斥判定
			var node_type_roll = prng.next_float()
			var level_data = {
				"id": level_id,
				"level": layer_idx + 1,
				"rounds": rounds,
				"next": []
			}
			
			var event_rate = profile.get("eventRate", 0.08)
			var rest_rate = profile.get("restRate", 0.10)
			var shop_rate = profile.get("shopRate", 0.12)
			
			if node_type_roll < event_rate:
				# 事件节点（从配置表随机抽取）
				var event_id = sample_event_by_difficulty(prng, profile, progress, true)
				level_data["events"] = [event_id]
			elif node_type_roll < event_rate + rest_rate:
				# 休息节点（从配置表随机抽取）
				var rest_id = sample_rest_by_difficulty(prng, profile, progress)
				level_data["rests"] = [rest_id]
			elif node_type_roll < event_rate + rest_rate + shop_rate:
				# 商店节点（仅layer_idx > 2生效，否则fallback战斗）
				if layer_idx > 2:
					var shop_id = sample_shop_by_difficulty(prng, profile, progress)
					level_data["shops"] = [shop_id]
				else:
					level_data["rounds"] = rounds
			else:
				# 战斗节点
				level_data["rounds"] = rounds
			
			current_layer.append(level_data)
			game_levels[level_id] = level_data
			level_id += 1
		
		layers.append(current_layer)
	
	# ========== 生成网状连接（单调区间分配，保证无交叉） ==========
	for layer_idx in range(layers.size() - 1):
		var current_layer_obj = layers[layer_idx]
		var next_layer_obj = layers[layer_idx + 1]
		
		if layer_idx == 0:
			# 第一层: 连接下一层全部节点
			for ni in range(next_layer_obj.size()):
				current_layer_obj[0]["next"].append(next_layer_obj[ni]["id"])
		elif layer_idx == layers.size() - 2:
			# 倒数第二层: 所有节点连接到最终BOSS
			for node in current_layer_obj:
				node["next"].append(next_layer_obj[0]["id"])
		else:
			# 单调区间分配
			var current_count = current_layer_obj.size()
			var next_count = next_layer_obj.size()
			var block_size = float(next_count) / float(current_count)
			
			# 建立下层ID到索引的映射
			var next_id_to_index = {}
			for ni in range(next_layer_obj.size()):
				next_id_to_index[next_layer_obj[ni]["id"]] = ni
			
			# 每个上层节点在自己的区间内选择连接
			for node_index in range(current_count):
				var start_idx = floor(node_index * block_size)
				var end_idx = floor((node_index + 1) * block_size) - 1
				if end_idx < start_idx:
					end_idx = start_idx
				
				# 强制严格非重叠
				if node_index > 0:
					var prev_end = floor((node_index - 1 + 1) * block_size) - 1
					start_idx = max(prev_end, start_idx)
					if start_idx > end_idx:
						end_idx = start_idx
				
				start_idx = max(0, start_idx)
				end_idx = min(next_count - 1, end_idx)
				
				var available_nodes = []
				for ni in range(start_idx, end_idx + 1):
					available_nodes.append(next_layer_obj[ni])
				
				if not available_nodes.is_empty():
					var out_count = 1 + floor(prng.next_float() * 3)  # 1~3个出口
					var select_count = min(out_count, available_nodes.size())
					
					# 随机选择
					var selected_indices = []
					while selected_indices.size() < select_count:
						var candidate = floor(prng.next_float() * float(available_nodes.size()))
						if not selected_indices.has(candidate):
							selected_indices.append(candidate)
					
					selected_indices.sort()
					for si in selected_indices:
						current_layer_obj[node_index]["next"].append(available_nodes[si]["id"])
			
			# 连通性保证：下层节点不能被遗漏
			for ni in range(next_count):
				var next_node = next_layer_obj[ni]
				var has_incoming = false
				for cn in current_layer_obj:
					if cn["next"].has(next_node["id"]):
						has_incoming = true
						break
				
				if not has_incoming:
					# 找到最优上层节点连接
					var target_node = null
					var target_node_idx = -1
					for ci in range(current_count):
						var s = floor(ci * block_size)
						var e = floor((ci + 1) * block_size) - 1
						if ni >= s and ni <= e:
							target_node = current_layer_obj[ci]
							target_node_idx = ci
							break
					
					if target_node != null and not target_node["next"].has(next_node["id"]):
						target_node["next"].append(next_node["id"])
	
	return game_levels

static func sample_round_by_difficulty(prng: Prng, profile: Dictionary, progress: float, elite_only: bool = false) -> int:
	var rounds = []
	for rid in MetaConsts.roundDifficulty.keys():
		var r = MetaConsts.roundDifficulty[rid].duplicate()
		r["id"] = rid
		rounds.append(r)
	
	# 根据进度过滤可用层级
	var min_tier = max(1, floor(progress * 13))
	var max_tier = min(15, min_tier + 3)
	
	var candidates = []
	for r in rounds:
		if r.get("tier", 1) >= min_tier and r.get("tier", 1) <= max_tier:
			candidates.append(r)
	
	if elite_only:
		candidates = candidates.filter(func(r): return r.get("difficulty", "") == "hard" or r.get("difficulty", "") == "expert")
	
	if candidates.is_empty():
		candidates = rounds
	
	# 加权随机: 更倾向高难度
	var weights = []
	for r in candidates:
		var tier_bonus = float(r.get("tier", 1)) * 0.5
		var diff_str = r.get("difficulty", "normal")
		var diff_bonus = 1.0
		if diff_str == "expert":
			diff_bonus = 2.0
		elif diff_str == "hard":
			diff_bonus = 1.5
		weights.append(tier_bonus * diff_bonus)
	
	var selected = prng.weighted_random_choice(candidates, weights)
	return selected.get("id", 50001) if selected else 50001

static func sample_shop_by_difficulty(prng: Prng, profile: Dictionary, progress: float) -> int:
	# 从 MetaConsts.gameShops 根据进度抽取（以 tier 字段为依据）
	var shop_tier = 1
	if progress < 0.33:
		shop_tier = 1
	elif progress < 0.66:
		shop_tier = 2
	else:
		shop_tier = 3
	
	# 在对应 tier 的 shops 中随机选一个
	var candidates = []
	for sid in MetaConsts.gameShops.keys():
		var shop = MetaConsts.gameShops[sid]
		if shop.get("tier", 1) == shop_tier:
			candidates.append(sid)
	
	if not candidates.is_empty():
		return prng.random_choice(candidates)
	return 60000 + shop_tier

static func sample_event_by_difficulty(prng: Prng, profile: Dictionary, progress: float, exclude_start: bool = true) -> int:
	# 从 MetaConsts.gameEvents 根据进度抽取
	var min_tier = max(1, floor(progress * 4))
	var max_tier = min(4, min_tier + 1)
	
	var candidates = []
	for eid in MetaConsts.gameEvents.keys():
		var event = MetaConsts.gameEvents[eid]
		var tier = event.get("tier", 1)
		if exclude_start and event.get("type", "") == "start_choice":
			continue  # 排除初始祝福
		if tier >= min_tier and tier <= max_tier:
			candidates.append(eid)
	
	if candidates.is_empty():
		# fallback: 排除 start_choice 后取所有
		for eid in MetaConsts.gameEvents.keys():
			var event = MetaConsts.gameEvents[eid]
			if exclude_start and event.get("type", "") == "start_choice":
				continue
			candidates.append(eid)
	
	if not candidates.is_empty():
		return prng.random_choice(candidates)
	return 70001  # 终极fallback

static func sample_rest_by_difficulty(prng: Prng, profile: Dictionary, progress: float) -> int:
	# 从 MetaConsts.gameRests 根据进度抽取
	var min_tier = max(1, floor(progress * 3))
	var max_tier = min(3, min_tier + 1)
	
	var candidates = []
	for rid in MetaConsts.gameRests.keys():
		var rest = MetaConsts.gameRests[rid]
		var tier = rest.get("tier", 1)
		if tier >= min_tier and tier <= max_tier:
			candidates.append(rid)
	
	if candidates.is_empty():
		candidates = MetaConsts.gameRests.keys()
	
	if not candidates.is_empty():
		return prng.random_choice(candidates)
	return 80001

static func generate_map(difficulty: int, seed: int) -> MapModel:
	var prng = Prng.new(seed)
	var map = MapModel.create_empty_map(difficulty, seed)
	var profile = map.profile
	
	# 生成三级结构数据
	map.game_rounds = generate_game_rounds(profile, prng)
	map.game_levels = generate_game_levels(profile, map.game_rounds, prng)
	
	# 获取节点数量限制
	var node_limits = profile.get("nodeLimits", {})
	var node_counts = {"battle": 0, "elite": 0, "boss": 0, "shop": 0, "event": 0, "rest": 0, "treasure": 0}
	var last_shop_index = -10
	var total_layers = profile.get("layerCount", 7)
	
	# 为每个真实关卡节点生成节点数据
	var level_ids = map.game_levels.keys()
	level_ids.sort()
	
	for index in range(level_ids.size()):
		var level_id = level_ids[index]
		var level = map.game_levels[level_id]
		var progress = float(level.get("level", 1)) / float(total_layers)
		
		var node = {
			"id": level_id,
			"index": index,
			"level": level.get("level", 1)
		}
		
		# 首层固定为初始祝福事件 (70004)
		if level.get("level", 1) == 1:
			node["type"] = "event"
			node["eventId"] = 70004
			node_counts["event"] += 1
		# 末层固定为最终Boss
		elif level.get("level", 1) == total_layers:
			node["type"] = "boss"
			node["roundId"] = 50015  # 最终Boss round
			node_counts["boss"] += 1
		else:
			var assigned = false
			
			# 辅助函数：检查某类型是否已达max
			var can_add = func(t: String) -> bool:
				var limits = node_limits.get(t, {})
				var max_val = limits.get("max", 999)
				return node_counts.get(t, 0) < max_val
			
			# 优先处理已有事件节点
			if not assigned and level.get("events", []).size() > 0 and can_add.call("event"):
				node["type"] = "event"
				node["eventId"] = level["events"][0]
				node_counts["event"] += 1
				assigned = true
			
			# 优先处理已有休息节点
			if not assigned and level.get("rests", []).size() > 0 and can_add.call("rest"):
				node["type"] = "rest"
				node["restId"] = level["rests"][0]
				node_counts["rest"] += 1
				assigned = true
			
			# 优先处理已有商店节点
			if not assigned and level.get("shops", []).size() > 0 and can_add.call("shop"):
				node["type"] = "shop"
				node["shopId"] = level["shops"][0]
				node_counts["shop"] += 1
				last_shop_index = index
				assigned = true
			
			if not assigned:
				# 战斗节点（含精英、宝箱、商店）
				# battle 是兜底类型，无 max 限制；shop/elite/treasure 受 max 限制
				var shop_rate = profile.get("shopRate", 0.12)
				var elite_rate = profile.get("eliteRate", 0.15)
				var distance_from_last_shop = index - last_shop_index
				
				if distance_from_last_shop < 3:
					shop_rate = 0.0
				
				var roll = prng.next_float()
				
				# 非 battle 类型受 max 限制，已达上限则概率设为0
				var effective_shop_rate = shop_rate if can_add.call("shop") else 0.0
				var elite_chance = (elite_rate * (0.5 + progress * 0.5)) if can_add.call("elite") else 0.0
				var treasure_chance = (0.10 * (0.5 + progress * 0.5)) if can_add.call("treasure") else 0.0
				
				var cum_prob = 0.0
				var threshold_shop = cum_prob + effective_shop_rate
				
				if roll < threshold_shop:
					node["type"] = "shop"
					node["shopId"] = sample_shop_by_difficulty(prng, profile, progress)
					node_counts["shop"] += 1
					last_shop_index = index
				else:
					var threshold_elite = threshold_shop + elite_chance
					if roll < threshold_elite:
						node["type"] = "elite"
						node["roundId"] = sample_round_by_difficulty(prng, profile, progress, true)
						node_counts["elite"] += 1
					else:
						var threshold_treasure = threshold_elite + treasure_chance
						if roll < threshold_treasure:
							node["type"] = "treasure"
							node["eventId"] = 70001  # 神秘宝箱事件
							node_counts["treasure"] += 1
						else:
							node["type"] = "battle"
							node["roundId"] = sample_round_by_difficulty(prng, profile, progress)
							node_counts["battle"] += 1
		
		# 抽样敌人池
		if node.has("roundId"):
			var round_data = map.game_rounds.get(node["roundId"], MetaConsts.gameRounds.get(node["roundId"], {}))
			if round_data.has("orderEnermyPool"):
				node["enemies"] = round_data["orderEnermyPool"].duplicate()
		
		# 难度修饰参数
		node["modifiers"] = {
			"hpMultiplier": profile.get("hpMultiplier", 1.0),
			"atkMultiplier": profile.get("atkMultiplier", 1.0),
			"stepReduction": profile.get("stepReduction", 1.0),
			"dropRate": profile.get("dropRate", 1.0)
		}
		
		map.layers.append(node)
	
	# ===== 后处理：确保每种节点达到 min 限制 =====
	for t in ["shop", "elite", "treasure", "event", "rest"]:
		var limits = node_limits.get(t, {})
		var min_val = limits.get("min", 0)
		var current_count = node_counts.get(t, 0)
		if current_count < min_val:
			var needed = min_val - current_count
			# 从 battle 节点中找可以转换的
			var battle_indices = []
			for i in range(map.layers.size()):
				if map.layers[i].get("type") == "battle":
					battle_indices.append(i)
			
			# 打乱顺序，随机选择
			battle_indices = prng.shuffle(battle_indices)
			for i in range(min(needed, battle_indices.size())):
				var target_idx = battle_indices[i]
				var node_ref = map.layers[target_idx]
				match t:
					"shop":
						node_ref["type"] = "shop"
						node_ref["shopId"] = sample_shop_by_difficulty(prng, profile, float(node_ref.get("level", 1)) / float(total_layers))
						node_ref.erase("roundId")
						node_ref.erase("enemies")
					"elite":
						node_ref["type"] = "elite"
						var p = float(node_ref.get("level", 1)) / float(total_layers)
						node_ref["roundId"] = sample_round_by_difficulty(prng, profile, p, true)
					"treasure":
						node_ref["type"] = "treasure"
						node_ref["eventId"] = 70001
						node_ref.erase("roundId")
						node_ref.erase("enemies")
					"event":
						node_ref["type"] = "event"
						var eid = sample_event_by_difficulty(prng, profile, float(node_ref.get("level", 1)) / float(total_layers), true)
						node_ref["eventId"] = eid
						node_ref.erase("roundId")
						node_ref.erase("enemies")
					"rest":
						node_ref["type"] = "rest"
						var rid = sample_rest_by_difficulty(prng, profile, float(node_ref.get("level", 1)) / float(total_layers))
						node_ref["restId"] = rid
						node_ref.erase("roundId")
						node_ref.erase("enemies")
				node_counts[t] += 1
	
	# 后处理校验
	if not MapModel.validate_map_model(map):
		GDLogger.error("Map validation failed: generated map is invalid")
	
	print_map_debug_log(map)

	return map

static func print_map_debug_log(map: MapModel) -> void:
	var node_icons = {
		"battle": "BATTLE",
		"elite": "ELITE",
		"boss": "BOSS",
		"shop": "SHOP",
		"event": "EVENT",
		"rest": "REST",
		"treasure": "TREASURE"
	}
	
	var stats = {"battle": 0, "elite": 0, "boss": 0, "shop": 0, "event": 0, "rest": 0, "treasure": 0}
	
	GDLogger.info("=== Map Generated | Difficulty: " + str(map.difficulty) + " | Layers: " + str(map.layers.size()) + " | Seed: " + str(map.seed))
	
	for idx in range(map.layers.size()):
		var node = map.layers[idx]
		var icon = node_icons.get(node.get("type", ""), "UNKNOWN")
		var round_id = node.get("roundId", 0)
		var enemies = []
		if node.has("enemies"):
			enemies = node["enemies"]
		
		# 输出额外字段
		var extra = ""
		var t = node.get("type", "")
		match t:
			"shop":
				extra = " | shopId=" + str(node.get("shopId", 0))
			"event":
				extra = " | eventId=" + str(node.get("eventId", 0))
			"rest":
				extra = " | restId=" + str(node.get("restId", 0))
			"treasure":
				extra = " | eventId=" + str(node.get("eventId", 0))
		
		# 统计
		if stats.has(t):
			stats[t] += 1
		
		GDLogger.info("  " + str(idx + 1) + " | " + icon + " | round=" + str(round_id) + " | enemies=" + str(enemies) + extra)
	
	GDLogger.info("=== Stats: " + str(stats))
