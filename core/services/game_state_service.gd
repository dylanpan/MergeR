class_name GameStateService

# ============================================================
# 游戏状态服务
# 管理回合、关卡、难度等游戏状态
# ============================================================

var cur_game_type: int = 1
var cur_level: int = 0
var cur_round_idx: int = 0
var round_total_step: int = 0

var runtime_map = null  # MapModel instance

# UI 流程参数
var temp_ui_difficulty: int = 5
var temp_ui_seed: int = 0

# 选择数据
var select_launchers: Array = []
var select_order_self_id: int = 0

# 记忆的回合数据
var _stages: Array = []

func _init():
	pass

# ==================== 关卡 ====================

func get_cur_level() -> int:
	return cur_level

func set_cur_level(value: int) -> void:
	cur_level = value

func get_cur_game_type() -> int:
	return cur_game_type

func to_next_level() -> void:
	if runtime_map:
		reset_round()
		set_cur_level(-2)
		return
	reset_round()
	var next_levels = MetaConsts.get("gameLevels", {}).get(cur_level, {}).get("next", [])
	if not next_levels.is_empty():
		set_cur_level(-1)
		set_cur_level(next_levels[0])
	else:
		set_cur_level(-2)

# ==================== 回合 ====================

func get_cur_round_idx() -> int:
	return cur_round_idx

func reset_round() -> void:
	cur_round_idx = 0

func add_round() -> void:
	if runtime_map:
		if cur_round_idx < runtime_map.layers.size() - 1:
			cur_round_idx += 1
		return
	var level_meta = MetaConsts.get("gameLevels", {}).get(cur_level, {})
	var round_ids = level_meta.get("rounds", [])
	if cur_round_idx < round_ids.size() - 1:
		cur_round_idx += 1

func is_cur_round_finish() -> bool:
	if runtime_map:
		return cur_round_idx >= runtime_map.layers.size() - 1
	var level_meta = MetaConsts.get("gameLevels", {}).get(cur_level, {})
	var round_ids = level_meta.get("rounds", [])
	return cur_round_idx >= round_ids.size() - 1

func get_cur_round_meta() -> Dictionary:
	if runtime_map:
		var node = runtime_map.layers[cur_round_idx]
		if node and node.get("roundId"):
			var round_data = runtime_map.game_rounds.get(node.roundId)
			if round_data:
				return round_data
	var level_meta = MetaConsts.get("gameLevels", {}).get(cur_level, {})
	var round_ids = level_meta.get("rounds", [])
	if cur_round_idx < round_ids.size():
		var round_id = round_ids[cur_round_idx]
		return MetaConsts.get("gameRounds", {}).get(round_id, {})
	return {}

# ==================== 步数 ====================

func add_round_total_step(value: int = 1) -> void:
	round_total_step += value

func get_round_total_step() -> int:
	return round_total_step

func reset_round_total_step() -> void:
	round_total_step = 0

func get_step_progress() -> Dictionary:
	var round_meta = get_cur_round_meta()
	var max_step = round_meta.get("step", 0) if round_meta else 0
	var current = round_total_step
	var progress = float(current) / float(max_step) if max_step > 0 else 0.0
	return {
		"current": current,
		"max": max_step,
		"progress": progress
	}

# ==================== Stages ====================

func add_stage(value) -> void:
	_stages.append(value)

func get_stages() -> Array:
	return _stages

func reset_stages() -> void:
	_stages.clear()

# ==================== 运行时地图 ====================

func set_runtime_map(map_model) -> void:
	runtime_map = map_model
	cur_level = 0
	cur_round_idx = 0

func clear_runtime_map() -> void:
	runtime_map = null

func has_runtime_map() -> bool:
	return runtime_map != null

func get_runtime_map():
	return runtime_map

# ==================== UI 临时数据 ====================

func set_ui_temp_data(difficulty: int, seed: int) -> void:
	temp_ui_difficulty = difficulty
	temp_ui_seed = seed

func get_ui_temp_difficulty() -> int:
	return temp_ui_difficulty

func get_ui_temp_seed() -> int:
	return temp_ui_seed

# ==================== 选择数据 ====================

func set_select_launchers(value: Array) -> void:
	select_launchers = value

func get_select_launchers() -> Array:
	return select_launchers

func set_select_order_self_id(value: int) -> void:
	select_order_self_id = value

func get_selected_character_template_id() -> int:
	return select_order_self_id

func get_selected_character_template() -> Dictionary:
	if not select_order_self_id:
		return {}
	return MetaConsts.get("orderSelf", {}).get(select_order_self_id, {})

# ==================== 重置 ====================

func reset() -> void:
	cur_game_type = 1
	cur_level = 0
	cur_round_idx = 0
	round_total_step = 0
	runtime_map = null
	temp_ui_difficulty = 5
	temp_ui_seed = 0
	select_launchers.clear()
	select_order_self_id = 0
	_stages.clear()