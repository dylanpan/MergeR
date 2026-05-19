class_name PersistenceService

# ============================================================
# 持久化服务
# 管理存档/读档
# ============================================================

var _game_data = null

func _init():
	pass

# ==================== 游戏数据 ====================

func get_cur_game_data():
	return _game_data

func set_cur_game_data(data) -> void:
	_game_data = data

func create_new_game_data(record_json = null, select_launchers: Array = [], select_order_self_id: int = 0, initial_cur_level: int = 0, initial_cur_round_idx: int = 0, runtime_map = null) -> Dictionary:
	var data = GameData.new()
	if record_json:
		data.load(record_json)
		_game_data = data
		return data
	
	var init_data = {}
	var _config = ClearRoguelikeManager.get_world().config_service if ClearRoguelikeManager.get_world() else null
	init_data["launchers"] = {
		0: _config.get_launcher(select_launchers[0]) if _config and select_launchers.size() > 0 else {},
		1: _config.get_launcher(select_launchers[1]) if _config and select_launchers.size() > 1 else {},
	}
	init_data["elements"] = {}
	init_data["shots"] = {}
	init_data["orderSelfId"] = select_order_self_id
	init_data["orderShop"] = []
	
	var round_meta = {}
	if runtime_map:
		var node = runtime_map.layers[initial_cur_round_idx]
		if node and node.get("roundId"):
			round_meta = runtime_map.game_rounds.get(node.roundId, {})
	
	if round_meta.is_empty():
		var level_meta = _config.get_game_level(initial_cur_level) if _config else {}
		var round_ids = level_meta.get("rounds", [])
		if initial_cur_round_idx < round_ids.size():
			var round_id = round_ids[initial_cur_round_idx]
			round_meta = _config.get_game_round(round_id) if _config else {}
	
	# 生成敌方单位
	init_data["orderEnermy"] = []
	var order_enermy_ids = round_meta.get("orderEnermyPool", [])
	for order_enermy_id in order_enermy_ids:
		var order_enermy_meta = _config.get_enemy(order_enermy_id) if _config else {}
		init_data["orderEnermy"].append({
			"id": order_enermy_meta.get("id", 0),
			"hp": order_enermy_meta.get("hp", 100),
			"def": order_enermy_meta.get("def", 0),
			"atk": order_enermy_meta.get("atk", 0),
			"step": order_enermy_meta.get("step", 0),
			"type": GameConsts.OrderType_Enermy,
			"isAtker": 0,
			"buff": 0,
			"bullets": [],
		})
	
	# 生成己方单位
	init_data["orderSelf"] = []
	var order_self_meta = _config.get_self(select_order_self_id) if _config else {}
	init_data["orderSelf"].append({
		"id": order_self_meta.get("id", 0),
		"hp": order_self_meta.get("hp", 100),
		"def": order_self_meta.get("def", 0),
		"atk": order_self_meta.get("atk", 0),
		"step": order_self_meta.get("step", 0),
		"type": GameConsts.OrderType_Self,
		"isAtker": 0,
		"buff": 0,
		"bullets": [],
	})
	
	data.load(init_data)
	_game_data = data
	return data

func reset() -> void:
	_game_data = null