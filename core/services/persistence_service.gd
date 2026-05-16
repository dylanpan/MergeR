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
	init_data["launchers"] = {
		0: MetaConsts.get("launchers", {}).get(select_launchers[0], {}) if select_launchers.size() > 0 else {},
		1: MetaConsts.get("launchers", {}).get(select_launchers[1], {}) if select_launchers.size() > 1 else {},
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
		var level_meta = MetaConsts.get("gameLevels", {}).get(initial_cur_level, {})
		var round_ids = level_meta.get("rounds", [])
		if initial_cur_round_idx < round_ids.size():
			var round_id = round_ids[initial_cur_round_idx]
			round_meta = MetaConsts.get("gameRounds", {}).get(round_id, {})
	
	# 生成敌方单位
	init_data["orderEnermy"] = []
	var order_enermy_ids = round_meta.get("orderEnermyPool", [])
	for order_enermy_id in order_enermy_ids:
		var order_enermy_meta = MetaConsts.get("orderEnermy", {}).get(order_enermy_id, {})
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
	var order_self_meta = MetaConsts.get("orderSelf", {}).get(select_order_self_id, {})
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
	
	init_data["level"] = initial_cur_level
	init_data["round"] = initial_cur_round_idx
	
	data.load(init_data)
	_game_data = data
	return data

func save_game(game_state_service, inventory_service) -> Dictionary:
	if not _game_data:
		return {}
	_game_data.level = game_state_service.get_cur_level()
	_game_data.round = game_state_service.get_cur_round_idx()
	_game_data.items = inventory_service.get_all_items()
	_game_data.currencies = inventory_service.get_all_currencies()
	return _game_data.to_json()

func load_game(save_data: Dictionary) -> bool:
	if not GameData.is_valid(save_data):
		return false
	_game_data = null
	create_new_game_data(save_data, [], 0, 0, 0)
	return true

func remove_order_game_data(data: Dictionary) -> void:
	if data.is_empty() or not _game_data:
		return
	var type_val = data.get("type", -1)
	match type_val:
		GameConsts.OrderType_Self:
			var idx = _game_data.orderSelf.find(data)
			if idx != -1:
				_game_data.orderSelf.remove_at(idx)
		GameConsts.OrderType_Enermy:
			var idx = _game_data.orderEnermy.find(data)
			if idx != -1:
				_game_data.orderEnermy.remove_at(idx)

func get_order_self_data() -> Dictionary:
	if not _game_data or not _game_data.get("orderSelf"):
		return {}
	var order_self = _game_data.orderSelf
	return order_self[0] if not order_self.is_empty() else {}

func get_all_self_datas() -> Array:
	if not _game_data or not _game_data.get("orderSelf"):
		return []
	return _game_data.orderSelf.duplicate()

# ==================== 存档数据协调（原 WorldDataManager.save_game_to_data） ====================

func prepare_game_data_for_save(entity_manager) -> void:
	"""
	将实体数据同步到存档数据（在保存前调用）
	"""
	if not _game_data or not entity_manager:
		return
	var all_types = [
		entity_manager.get_by_type(3),  # ELEMENT
		entity_manager.get_by_type(4),  # LAUNCHER
		entity_manager.get_by_type(5),  # BULLET
		entity_manager.get_by_type(6),  # SHOT
		entity_manager.get_by_type(1),  # ORDER_SELF
		entity_manager.get_by_type(2),  # ORDER_ENEMY
	]
	for list in all_types:
		for entity in list:
			if entity and entity.has_method("sync_to_data"):
				entity.sync_to_data()
			elif entity and entity.has_method("get_component"):
				var data_comp = entity.get_component(ComponentNames.DATA)
				var buff_comp = entity.get_component(ComponentNames.BUFF)
				if data_comp and data_comp.data and buff_comp and buff_comp.has_method("to_json"):
					data_comp.data["buffs"] = buff_comp.to_json()

func save_game_with_services(game_state_service, inventory_service, entity_manager) -> Dictionary:
	"""
	保存游戏：先同步实体数据到存档，再序列化
	等价于 WorldDataManager.save_game()
	"""
	if not _game_data:
		return {}
	prepare_game_data_for_save(entity_manager)
	_game_data.level = game_state_service.get_cur_level()
	_game_data.round = game_state_service.get_cur_round_idx()
	_game_data.items = inventory_service.get_all_items()
	_game_data.currencies = inventory_service.get_all_currencies()
	return _game_data.to_json()

func reset() -> void:
	_game_data = null
