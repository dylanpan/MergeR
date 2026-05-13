extends Node

# ============================================================
# 世界数据管理器（替代 WorldDataManager.js）
# Godot Autoload 单例 - 整个游戏的数据中心
# ============================================================

var _world = null
var _entity_manager = null
var _game_data = null

# UI 根节点引用
var _element_ui_root = null
var _launcher_ui_root = null
var _bullet_ui_root = null
var _order_ui_root = null
var _attack_ui_root = null

# 实体列表
var _element_entities: Array = []
var _launcher_entities: Array = []
var _bullet_entities: Array = []
var _shot_entities: Array = []
var _order_entities: Array = []
var _order_self_entities: Array = []
var _order_enermy_entities: Array = []
var _shop_entities: Array = []
var _event_entities: Array = []
var _stages: Array = []

# 游戏状态
var _round_total_step: int = 0
var _cur_game_type: int = 1
var _cur_level: int = 0
var _cur_round_idx: int = 0
var _init_flag: bool = false

# 选择数据
var _select_launchers: Array = []
var _select_order_self_id: int = 0

# 界面间传递的临时数据（UI 流程参数）
var _temp_ui_difficulty: int = 5
var _temp_ui_seed: int = 0

# 运行时地图
var _runtime_map = null  # MapModel instance

# 单局道具和货币
var _items: Dictionary = {}
var _currencies: Dictionary = {}

# 全局实体ID映射表 O(1)查询
var _entity_map: Dictionary = {}

func _ready():
	# 初始化随机数种子
	var seed_val = Time.get_unix_time_from_system()
	seed(seed_val)
	
	# 尝试加载上次存档
	var config = ConfigFile.new()
	if config.load("user://clear_roguelike_save.cfg") == OK:
		var save_json = config.get_value("save", "clear_roguelike_last", "")
		if not save_json.is_empty():
			var json = JSON.new()
			var parse_result = json.parse(save_json)
			if parse_result == OK and json.data is Dictionary:
				load_game(json.data)
				print("WorldDataManager: 已恢复上次存档")

func set_world(world) -> void:
	_world = world

func get_world():
	return _world

func set_entity_manager(em) -> void:
	_entity_manager = em

func get_entity_manager():
	return _entity_manager

func set_init_flag(value: bool) -> void:
	_init_flag = value

func get_init_flag() -> bool:
	return _init_flag

# ---- UI Root ----
func add_element_ui_root(root) -> void:
	_element_ui_root = root

func get_element_ui_root():
	return _element_ui_root

func add_launcher_ui_root(root) -> void:
	_launcher_ui_root = root

func get_launcher_ui_root():
	return _launcher_ui_root

func add_bullet_ui_root(root) -> void:
	_bullet_ui_root = root

func get_bullet_ui_root():
	return _bullet_ui_root

func add_order_ui_root(root) -> void:
	_order_ui_root = root

func get_order_ui_root():
	return _order_ui_root

func add_attack_ui_root(root) -> void:
	_attack_ui_root = root

func get_attack_ui_root():
	return _attack_ui_root

# ---- Entity Management ----
func add_order_entity(entity) -> void:
	_order_entities.append(entity)
	_entity_map[entity.get_id()] = entity
	if _entity_manager:
		_entity_manager.register_entity(entity)
	var data_comp = entity.get_component("Data")
	if data_comp and data_comp.data:
		var data = data_comp.data
		if data.get("type") == GameConsts.OrderType_Self:
			_order_self_entities.append(entity)
		elif data.get("type") == GameConsts.OrderType_Enermy:
			_order_enermy_entities.append(entity)

func remove_order_self_entity(entity) -> void:
	var idx = _order_self_entities.find(entity)
	if idx != -1:
		_order_self_entities.remove_at(idx)
	idx = _order_entities.find(entity)
	if idx != -1:
		_order_entities.remove_at(idx)
	_entity_map.erase(entity.get_id())
	if _entity_manager:
		_entity_manager.unregister_entity(entity)

func remove_order_enermy_entity(entity) -> void:
	var idx = _order_enermy_entities.find(entity)
	if idx != -1:
		_order_enermy_entities.remove_at(idx)
	idx = _order_entities.find(entity)
	if idx != -1:
		_order_entities.remove_at(idx)
	_entity_map.erase(entity.get_id())
	if _entity_manager:
		_entity_manager.unregister_entity(entity)

func get_order_entities() -> Array:
	return _order_entities

func add_element_entity(entity) -> void:
	_element_entities.append(entity)
	_entity_map[entity.get_id()] = entity
	if _entity_manager:
		_entity_manager.register_entity(entity)

func add_launcher_entity(entity) -> void:
	_launcher_entities.append(entity)
	_entity_map[entity.get_id()] = entity
	if _entity_manager:
		_entity_manager.register_entity(entity)

func add_bullet_entity(entity) -> void:
	_bullet_entities.append(entity)
	_entity_map[entity.get_id()] = entity
	if _entity_manager:
		_entity_manager.register_entity(entity)

func get_bullet_entities() -> Array:
	return _bullet_entities

func add_shot_entity(entity) -> void:
	_shot_entities.append(entity)
	_entity_map[entity.get_id()] = entity
	if _entity_manager:
		_entity_manager.register_entity(entity)

func get_shot_entities() -> Array:
	return _shot_entities

func get_empty_element_entity():
	for entity in _element_entities:
		var data_comp = entity.get_component("Data")
		if not data_comp or not data_comp.data:
			return entity
	return null

# 根据发射器配置从 MetaConsts 中选择合适的子弹数据
func _get_element_type(element_meta: Dictionary) -> int:
	if not element_meta:
		return 0
	var element_types = element_meta.get("elementType")
	if not element_types:
		return 0
	var list = []
	if element_types is Array:
		for it in element_types:
			if it is int:
				list.append({"type": it, "weight": 1})
			elif it is Dictionary:
				var t = it.get("type", it.get("elementType", null))
				var w = it.get("weight", 1)
				if t != null:
					list.append({"type": t, "weight": max(0, w if w is int else 1)})
	elif element_types is Dictionary:
		var t = element_types.get("type", element_types.get("elementType", null))
		var w = element_types.get("weight", 1)
		if t != null:
			list.append({"type": t, "weight": max(0, w if w is int else 1)})
	if list.is_empty():
		return 0
	var total = 0
	for item in list:
		total += item.weight
	if total <= 0:
		total = list.size()
		for item in list:
			item.weight = 1
	var rnd = randf() * total
	var acc = 0
	for item in list:
		acc += item.weight
		if rnd < acc:
			return item.type
	return list[-1].type

func create_element_data(id: int) -> Dictionary:
	var DEFAULT_BULLET_ID = 8001
	var element_meta = MetaConsts.get("launchers", {}).get(id, null)
	if not element_meta:
		var fallback_meta = MetaConsts.get("elements", {}).get(DEFAULT_BULLET_ID, null)
		if fallback_meta:
			return {
				"id": fallback_meta.get("id", DEFAULT_BULLET_ID),
				"type": fallback_meta.get("type", 1),
				"atk": fallback_meta.get("atk", 0),
				"distance": fallback_meta.get("distance", fallback_meta.get("range", 0)),
				"cover": fallback_meta.get("cover", 0),
				"elementType": fallback_meta.get("elementType", 0),
			}
		return {"id": DEFAULT_BULLET_ID, "type": 1, "elementType": 0}
	var chosen_element_type = _get_element_type(element_meta)
	var TYPE_TO_BULLET = {
		1: 1001, # 火
		2: 2001, # 水
		3: 4001, # 风
		4: 6001, # 土
		0: 8001, # 无属性
	}
	var bullet_id = TYPE_TO_BULLET.get(chosen_element_type, DEFAULT_BULLET_ID)
	var bullet_meta = MetaConsts.get("elements", {}).get(bullet_id, null)
	var meta = bullet_meta if bullet_meta else MetaConsts.get("elements", {}).get(DEFAULT_BULLET_ID, null)
	if meta:
		return {
			"id": meta.get("id", bullet_id),
			"type": meta.get("type", 1),
			"atk": meta.get("atk", 0),
			"distance": meta.get("distance", meta.get("range", 0)),
			"cover": meta.get("cover", 0),
			"elementType": meta.get("elementType", chosen_element_type),
		}
	return {"id": bullet_id, "type": 1, "elementType": chosen_element_type}

func can_element_merge(e1, e2) -> bool:
	var data1 = e1.get_component("Data").data if e1.get_component("Data") else null
	var data2 = e2.get_component("Data").data if e2.get_component("Data") else null
	if data1 and data2:
		var meta = MetaConsts.get("elements", {}).get(data2["id"], null)
		return data1["id"] == data2["id"] and meta and meta.get("mergeId", 0) > 0
	return false

func get_element_merge_output_data(entity) -> Dictionary:
	var data_comp = entity.get_component("Data")
	if data_comp and data_comp.data:
		var data = data_comp.data
		var meta = MetaConsts.get("elements", {}).get(data["id"], null)
		if meta:
			return {"id": meta["mergeId"], "type": 1}
	return {}

func add_stage(value) -> void:
	_stages.append(value)

func get_stages() -> Array:
	return _stages

func reset_stages() -> void:
	_stages.clear()

func get_order_self_entities() -> Array:
	return _order_self_entities

func add_shop_entity(entity) -> void:
	_shop_entities.append(entity)
	_entity_map[entity.get_id()] = entity
	if _entity_manager:
		_entity_manager.register_entity(entity)

func remove_shop_entity(entity) -> void:
	var idx = _shop_entities.find(entity)
	if idx != -1:
		_shop_entities.remove_at(idx)
	_entity_map.erase(entity.get_id())
	if _entity_manager:
		_entity_manager.unregister_entity(entity)

func get_shop_entities() -> Array:
	return _shop_entities

func add_event_entity(entity) -> void:
	_event_entities.append(entity)
	_entity_map[entity.get_id()] = entity
	if _entity_manager:
		_entity_manager.register_entity(entity)

func remove_event_entity(entity) -> void:
	var idx = _event_entities.find(entity)
	if idx != -1:
		_event_entities.remove_at(idx)
	_entity_map.erase(entity.get_id())
	if _entity_manager:
		_entity_manager.unregister_entity(entity)

func get_event_entities() -> Array:
	return _event_entities

func remove_all_entities() -> void:
	for entity in _element_entities:
		entity.dispose()
	for entity in _launcher_entities:
		entity.dispose()
	for entity in _bullet_entities:
		entity.dispose()
	for entity in _order_entities:
		entity.dispose()
	for entity in _shop_entities:
		entity.dispose()
	for entity in _event_entities:
		entity.dispose()
	_element_entities.clear()
	_launcher_entities.clear()
	_bullet_entities.clear()
	_shot_entities.clear()
	_order_entities.clear()
	_order_self_entities.clear()
	_order_enermy_entities.clear()
	_shop_entities.clear()
	_event_entities.clear()
	_stages.clear()
	_round_total_step = 0
	_cur_game_type = 1
	_cur_level = 0
	_cur_round_idx = 0
	_element_ui_root = null
	_order_ui_root = null
	_game_data = null
	_entity_map.clear()
	clear_items()
	clear_currencies()

func get_order_enermy_entities() -> Array:
	return _order_enermy_entities

func add_round_total_step(value: int = 1) -> void:
	_round_total_step += value

func get_round_total_step() -> int:
	return _round_total_step

func reset_round_total_step() -> void:
	_round_total_step = 0

func get_step_progress() -> Dictionary:
	var round_meta = get_cur_round_meta()
	var max_step = round_meta.get("step", 0) if round_meta else 0
	var current = _round_total_step
	var progress = float(current) / float(max_step) if max_step > 0 else 0.0
	return {
		"current": current,
		"max": max_step,
		"progress": progress
	}

func update_step() -> void:
	add_round_total_step()
	for entity in _order_enermy_entities:
		var data_comp = entity.get_component("Data")
		if data_comp and data_comp.data:
			var data = data_comp.data
			var step = data.get("step", 0)
			if step and not data.get("isPreAtker", false):
				data["step"] = step - 1

func get_cur_game_type() -> int:
	return _cur_game_type

func get_cur_level() -> int:
	return _cur_level

func set_cur_level(value: int) -> void:
	_cur_level = value

func to_next_level() -> void:
	if _runtime_map:
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

func reset_round() -> void:
	_cur_round_idx = 0

func add_round() -> void:
	if _runtime_map:
		if _cur_round_idx < _runtime_map.layers.size() - 1:
			_cur_round_idx += 1
		return
	var cur_level = get_cur_level()
	var round_ids = MetaConsts.get("gameLevels", {}).get(cur_level, {}).get("rounds", [])
	if _cur_round_idx < round_ids.size() - 1:
		_cur_round_idx += 1

func get_cur_round_idx() -> int:
	return _cur_round_idx

func get_cur_round_meta() -> Dictionary:
	if _runtime_map:
		var node = _runtime_map.layers[_cur_round_idx]
		if node and node.get("roundId"):
			var round_data = _runtime_map.game_rounds.get(node.roundId)
			if round_data:
				return round_data
	var cur_level = get_cur_level()
	var cur_round_idx = get_cur_round_idx()
	var round_ids = MetaConsts.get("gameLevels", {}).get(cur_level, {}).get("rounds", [])
	if cur_round_idx < round_ids.size():
		var round_id = round_ids[cur_round_idx]
		return MetaConsts.get("gameRounds", {}).get(round_id, {})
	return {}

func is_cur_round_finish() -> bool:
	if _runtime_map:
		return _cur_round_idx >= _runtime_map.layers.size() - 1
	var cur_level = get_cur_level()
	var round_ids = MetaConsts.get("gameLevels", {}).get(cur_level, {}).get("rounds", [])
	return _cur_round_idx >= round_ids.size() - 1

func get_cur_game_data():
	return _game_data

func prepare_game_data_for_save() -> void:
	if not _game_data:
		return
	var sync_entity_list = func(list):
		for entity in list:
			if entity and entity.has_method("sync_to_data"):
				entity.sync_to_data()
			elif entity and entity.has_method("get_component"):
				var data_comp = entity.get_component("Data")
				var buff_comp = entity.get_component("Buff")
				if data_comp and data_comp.data and buff_comp and buff_comp.has_method("to_json"):
					data_comp.data["buffs"] = buff_comp.to_json()
	sync_entity_list.call(_element_entities)
	sync_entity_list.call(_launcher_entities)
	sync_entity_list.call(_bullet_entities)
	sync_entity_list.call(_shot_entities)
	sync_entity_list.call(_order_entities)
	sync_entity_list.call(_order_self_entities)
	sync_entity_list.call(_order_enermy_entities)
	sync_entity_list.call(_shop_entities)
	sync_entity_list.call(_event_entities)

func set_select_launchers(value: Array) -> void:
	_select_launchers = value

func set_select_order_self_id(value: int) -> void:
	_select_order_self_id = value

func get_selected_character_template_id() -> int:
	return _select_order_self_id

func get_selected_character_template() -> Dictionary:
	if not _select_order_self_id:
		return {}
	return MetaConsts.get("orderSelf", {}).get(_select_order_self_id, {})

func get_all_self_entities() -> Array:
	return _order_self_entities.duplicate()

func get_order_self_entity():
	return _order_self_entities[0] if not _order_self_entities.is_empty() else null

func get_all_self_datas() -> Array:
	if not _game_data or not _game_data.get("orderSelf"):
		return []
	return _game_data.orderSelf.duplicate()

func get_order_self_data():
	if not _game_data or not _game_data.get("orderSelf"):
		return null
	var order_self = _game_data.orderSelf
	return order_self[0] if not order_self.is_empty() else null

func has_alive_self() -> bool:
	for entity in _order_self_entities:
		var data_comp = entity.get_component("Data")
		if data_comp and data_comp.data:
			var hp = data_comp.data.get("hp", 0)
			if hp > 0:
				return true
	return false

func get_self_entity_by_uid(runtime_uid) -> EntityBase:
	for entity in _order_self_entities:
		if entity.uid == runtime_uid:
			return entity
	return null

func create_new_game_data(record_json = null):
	var data = GameData.new()
	if record_json:
		data.load(record_json)
		_items = data.items.duplicate() if data.items else {}
		_currencies = data.currencies.duplicate() if data.currencies else {}
		_cur_level = data.level
		_cur_round_idx = data.round
	else:
		var init_data = {}
		init_data["launchers"] = {
			0: MetaConsts.get("launchers", {}).get(_select_launchers[0], {}) if _select_launchers.size() > 0 else {},
			1: MetaConsts.get("launchers", {}).get(_select_launchers[1], {}) if _select_launchers.size() > 1 else {},
		}
		init_data["elements"] = {}
		init_data["shots"] = {}
		init_data["orderSelfId"] = _select_order_self_id
		init_data["orderShop"] = []
		
		var cur_game_type = get_cur_game_type()
		var cur_round_idx = get_cur_round_idx()
		var round_meta = {}
		
		if _runtime_map:
			var node = _runtime_map.layers[cur_round_idx]
			if node and node.get("roundId"):
				round_meta = _runtime_map.game_rounds.get(node.roundId, {})
		
		if round_meta.is_empty():
			var level_id = MetaConsts.get("gameStartLevel", {}).get(cur_game_type, 0)
			set_cur_level(level_id)
			var level_meta = MetaConsts.get("gameLevels", {}).get(level_id, {})
			var round_ids = level_meta.get("rounds", [])
			if cur_round_idx < round_ids.size():
				var round_id = round_ids[cur_round_idx]
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
		var order_self_meta = MetaConsts.get("orderSelf", {}).get(_select_order_self_id, {})
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
		
		init_data["level"] = _cur_level
		init_data["round"] = _cur_round_idx
		
		data.load(init_data)
		clear_items()
		clear_currencies()
	
	_game_data = data
	return data

func save_game() -> Dictionary:
	if not _game_data:
		return {}
	prepare_game_data_for_save()
	_game_data.level = _cur_level
	_game_data.round = _cur_round_idx
	_game_data.items = _items.duplicate()
	_game_data.currencies = _currencies.duplicate()
	return _game_data.to_json()

func load_game(save_data: Dictionary) -> bool:
	if not GameData.is_valid(save_data):
		return false
	remove_all_entities()
	create_new_game_data(save_data)
	return true

func remove_order_game_data(data: Dictionary) -> void:
	if data.is_empty():
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

func process_order_defeated(entity) -> void:
	var data_comp = entity.get_component("Data")
	if not data_comp or not data_comp.data:
		return
	var data = data_comp.data
	if data.get("type") == GameConsts.OrderType_Enermy and data.get("hp", 0) <= 0:
		var order_meta = MetaConsts.get("orderEnermy", {}).get(data["id"], {})
		var drop_items = order_meta.get("dropItems", [])
		_process_drop_items(drop_items)

func _process_drop_items(drop_items: Array) -> void:
	for drop_item in drop_items:
		var chance = drop_item.get("chance", 0.0)
		var item_id = drop_item.get("itemId", 0)
		var count = drop_item.get("count", 1)
		if randf() < chance:
			add_item(item_id, count)

func create_order_enermy_data(round_meta: Dictionary, modifiers = null) -> Array:
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
	var current_round = get_cur_round_idx()
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

func _get_difficulty_config(round_meta: Dictionary) -> Dictionary:
	var round_id = round_meta.get("id", 0)
	var round_difficulty = MetaConsts.get("roundDifficulty", {}).get(round_id, {})
	var difficulty_type = round_difficulty.get("difficulty", "normal")
	var difficulty_config = MetaConsts.get("difficultyCurves", {}).get(difficulty_type, {})
	return difficulty_config if not difficulty_config.is_empty() else MetaConsts.get("difficultyCurves", {}).get("normal", {})

# ---- UI 临时数据（用于界面间传递参数）----
func set_ui_temp_data(difficulty: int, seed: int) -> void:
	_temp_ui_difficulty = difficulty
	_temp_ui_seed = seed

func get_ui_temp_difficulty() -> int:
	return _temp_ui_difficulty

func get_ui_temp_seed() -> int:
	return _temp_ui_seed

func set_runtime_map(map_model) -> void:
	_runtime_map = map_model
	_cur_level = 0
	_cur_round_idx = 0

func clear_runtime_map() -> void:
	_runtime_map = null

func get_entity_by_id(entity_id: String):
	return _entity_map.get(entity_id, null)

func get_element_entities() -> Array:
	return _element_entities

func get_launcher_entities() -> Array:
	return _launcher_entities

func add_item(item_id: int, count: int = 1) -> void:
	_items[item_id] = _items.get(item_id, 0) + count

func remove_item(item_id: int, count: int = 1) -> void:
	var current = _items.get(item_id, 0)
	if current <= count:
		_items.erase(item_id)
	else:
		_items[item_id] = current - count

func get_item_count(item_id: int) -> int:
	return _items.get(item_id, 0)

func clear_items() -> void:
	_items.clear()

func add_currency(currency_id: int, count: int = 1) -> void:
	_currencies[currency_id] = _currencies.get(currency_id, 0) + count

func remove_currency(currency_id: int, count: int = 1) -> void:
	var current = _currencies.get(currency_id, 0)
	if current <= count:
		_currencies.erase(currency_id)
	else:
		_currencies[currency_id] = current - count

func get_currency_count(currency_id: int) -> int:
	return _currencies.get(currency_id, 0)

func clear_currencies() -> void:
	_currencies.clear()

func has_runtime_map() -> bool:
	return _runtime_map != null

func get_runtime_map():
	return _runtime_map

# 检查是否拥有足够数量的道具
func has_item(item_id: int, count: int = 1) -> bool:
	return get_item_count(item_id) >= count

# 获取全部道具映射表
func get_all_items() -> Dictionary:
	return _items.duplicate()

# 获取全部货币映射表
func get_all_currencies() -> Dictionary:
	return _currencies.duplicate()

# 检查货币是否足够
func has_enough_currency(currency_id: int, value: int) -> bool:
	return get_currency_count(currency_id) >= value

# 消费货币（消耗指定数量，余额不足返回false）
func spend_currency(currency_id: int, value: int) -> bool:
	if not has_enough_currency(currency_id, value):
		return false
	_currencies[currency_id] = _currencies.get(currency_id, 0) - value
	if _currencies[currency_id] <= 0:
		_currencies.erase(currency_id)
	return true

# 根据实体类型自动添加到对应列表
func add_entity(entity) -> void:
	if not entity:
		return
	if entity.has_method("get_component"):
		var data_comp = entity.get_component("Data") as DataComponent
		if data_comp and data_comp.data:
			var type_val = data_comp.data.get("type", 0)
			if type_val == GameConsts.OrderType_Self or type_val == GameConsts.OrderType_Enermy:
				add_order_entity(entity)
				return
	add_element_entity(entity)
