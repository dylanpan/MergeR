class_name GameStateManager

# ============================================================
# 游戏状态管理器
# 负责回合、关卡、难度等游戏流程状态
# ============================================================

var _cur_game_type: int = 1
var _cur_level: int = 0
var _cur_round_idx: int = 0
var _round_total_step: int = 0
var _init_flag: bool = false

# 选择数据
var _select_launchers: Array = []
var _select_order_self_id: int = 0

# UI 流程临时参数
var _temp_ui_difficulty: int = 5
var _temp_ui_seed: int = 0

# ==================== Init Flag ====================

func set_init_flag(value: bool) -> void:
	_init_flag = value

func get_init_flag() -> bool:
	return _init_flag

# ==================== Game Type / Level ====================

func get_cur_game_type() -> int:
	return _cur_game_type

func get_cur_level() -> int:
	return _cur_level

func set_cur_level(value: int) -> void:
	_cur_level = value

func to_next_level(runtime_map_exists: bool) -> void:
	if runtime_map_exists:
		reset_round()
		set_cur_level(-2)
		return
	reset_round()
	var cur_level = get_cur_level()
	var next_levels = MetaConsts.get("gameLevels", {}).get(cur_level, {}).get("next", [])
	if not next_levels.is_empty():
		set_cur_level(-1)
		set_cur_level(next_levels[0])
	else:
		set_cur_level(-2)

# ==================== Round ====================

func get_cur_round_idx() -> int:
	return _cur_round_idx

func reset_round() -> void:
	_cur_round_idx = 0

func add_round(runtime_map) -> void:
	if runtime_map:
		if _cur_round_idx < runtime_map.layers.size() - 1:
			_cur_round_idx += 1
		return
	var cur_level = get_cur_level()
	var round_ids = MetaConsts.get("gameLevels", {}).get(cur_level, {}).get("rounds", [])
	if _cur_round_idx < round_ids.size() - 1:
		_cur_round_idx += 1

func is_cur_round_finish(runtime_map) -> bool:
	if runtime_map:
		return _cur_round_idx >= runtime_map.layers.size() - 1
	var cur_level = get_cur_level()
	var round_ids = MetaConsts.get("gameLevels", {}).get(cur_level, {}).get("rounds", [])
	return _cur_round_idx >= round_ids.size() - 1

func get_cur_round_meta(runtime_map) -> Dictionary:
	if runtime_map:
		var node = runtime_map.layers[_cur_round_idx]
		if node and node.get("roundId"):
			var round_data = runtime_map.game_rounds.get(node.roundId)
			if round_data:
				return round_data
	var cur_level = get_cur_level()
	var cur_round_idx = get_cur_round_idx()
	var round_ids = MetaConsts.get("gameLevels", {}).get(cur_level, {}).get("rounds", [])
	if cur_round_idx < round_ids.size():
		var round_id = round_ids[cur_round_idx]
		return MetaConsts.get("gameRounds", {}).get(round_id, {})
	return {}

# ==================== Step ====================

func add_round_total_step(value: int = 1) -> void:
	_round_total_step += value

func get_round_total_step() -> int:
	return _round_total_step

func reset_round_total_step() -> void:
	_round_total_step = 0

func get_step_progress(runtime_map) -> Dictionary:
	var round_meta = get_cur_round_meta(runtime_map)
	var max_step = round_meta.get("step", 0) if round_meta else 0
	var current = _round_total_step
	var progress = float(current) / float(max_step) if max_step > 0 else 0.0
	return {
		"current": current,
		"max": max_step,
		"progress": progress
	}

func update_step(enermy_entities: Array) -> void:
	add_round_total_step()
	for entity in enermy_entities:
		var data_comp = entity.get_component(ComponentNames.DATA)
		if data_comp and data_comp.data:
			var data = data_comp.data
			var step = data.get("step", 0)
			if step and not data.get("isPreAtker", false):
				data["step"] = step - 1

# ==================== Selection Data ====================

func set_select_launchers(value: Array) -> void:
	_select_launchers = value

func get_select_launchers() -> Array:
	return _select_launchers

func set_select_order_self_id(value: int) -> void:
	_select_order_self_id = value

func get_selected_character_template_id() -> int:
	return _select_order_self_id

func get_selected_character_template() -> Dictionary:
	if not _select_order_self_id:
		return {}
	return MetaConsts.get("orderSelf", {}).get(_select_order_self_id, {})

# ==================== UI Temp Data ====================

func set_ui_temp_data(difficulty: int, seed: int) -> void:
	_temp_ui_difficulty = difficulty
	_temp_ui_seed = seed

func get_ui_temp_difficulty() -> int:
	return _temp_ui_difficulty

func get_ui_temp_seed() -> int:
	return _temp_ui_seed

# ==================== Reset ====================

func reset() -> void:
	_round_total_step = 0
	_cur_game_type = 1
	_cur_level = 0
	_cur_round_idx = 0