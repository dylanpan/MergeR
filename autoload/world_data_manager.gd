extends Node

# ============================================================
# 世界数据管理器 — 精简门面（Facade）
# 
# 【架构重构说明】
# 此类已从"上帝类"精简为薄门面层，职责已拆分到以下服务：
#   - GameStateService  → 回合/关卡/地图
#   - InventoryService  → 物品/货币
#   - PersistenceService → 存档/读档
#   - UIRootService     → UI 根节点
#   - EntityService     → 实体 CRUD（已有）
# 
# 新代码应通过 ClearRoguelikeManager 的 get_xxx_service() 获取服务实例，
# 不要再直接新增调用本类的方法。
# ============================================================

var _world = null
var _entity_manager = null

# 初始化标志
var _init_flag: bool = false

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
				# 向后兼容：通过 PersistenceService 加载
				# 注意：此时代 World 尚未创建，只做数据恢复标记
				print("WorldDataManager: 已恢复上次存档")

# ==================== 内部服务代理 ====================

func _get_game_state_service():
	return _world.game_state_service if _world else null

func _get_inventory_service():
	return _world.inventory_service if _world else null

func _get_persistence_service():
	return _world.persistence_service if _world else null

func _get_ui_root_service():
	return _world.ui_root_service if _world else null

func _get_entity_service():
	return _world.entity_service if _world else null

# ==================== World 引用 ====================

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

# ==================== UI Root（委托给 UIRootService） ====================

func add_element_ui_root(root) -> void:
	var s = _get_ui_root_service()
	if s: s.set_element_ui_root(root)

func get_element_ui_root():
	var s = _get_ui_root_service()
	return s.get_element_ui_root() if s else null

func add_launcher_ui_root(root) -> void:
	var s = _get_ui_root_service()
	if s: s.set_launcher_ui_root(root)

func get_launcher_ui_root():
	var s = _get_ui_root_service()
	return s.get_launcher_ui_root() if s else null

func add_bullet_ui_root(root) -> void:
	var s = _get_ui_root_service()
	if s: s.set_bullet_ui_root(root)

func get_bullet_ui_root():
	var s = _get_ui_root_service()
	return s.get_bullet_ui_root() if s else null

func add_order_ui_root(root) -> void:
	var s = _get_ui_root_service()
	if s: s.set_order_ui_root(root)

func get_order_ui_root():
	var s = _get_ui_root_service()
	return s.get_order_ui_root() if s else null

func add_attack_ui_root(root) -> void:
	var s = _get_ui_root_service()
	if s: s.set_attack_ui_root(root)

func get_attack_ui_root():
	var s = _get_ui_root_service()
	return s.get_attack_ui_root() if s else null

# ==================== 实体管理（委托给 EntityManager） ====================

func add_order_entity(entity) -> void:
	if _entity_manager:
		_entity_manager.register_entity(entity)

func remove_order_self_entity(entity) -> void:
	if _entity_manager:
		_entity_manager.unregister_entity(entity)

func remove_order_enermy_entity(entity) -> void:
	if _entity_manager:
		_entity_manager.unregister_entity(entity)

func get_order_entities() -> Array:
	if not _entity_manager:
		return []
	var result = _entity_manager.get_by_type(EntityType.ORDER_SELF)
	result.append_array(_entity_manager.get_by_type(EntityType.ORDER_ENEMY))
	return result

func add_element_entity(entity) -> void:
	if _entity_manager:
		_entity_manager.register_entity(entity)

func get_element_entities() -> Array:
	if not _entity_manager:
		return []
	return _entity_manager.get_by_type(3)  # EntityType.ELEMENT

func add_launcher_entity(entity) -> void:
	if _entity_manager:
		_entity_manager.register_entity(entity)

func get_launcher_entities() -> Array:
	if not _entity_manager:
		return []
	return _entity_manager.get_by_type(4)  # EntityType.LAUNCHER

func add_bullet_entity(entity) -> void:
	if _entity_manager:
		_entity_manager.register_entity(entity)

func get_bullet_entities() -> Array:
	if not _entity_manager:
		return []
	return _entity_manager.get_by_type(5)  # EntityType.BULLET

func add_shot_entity(entity) -> void:
	if _entity_manager:
		_entity_manager.register_entity(entity)

func get_shot_entities() -> Array:
	if not _entity_manager:
		return []
	return _entity_manager.get_by_type(6)  # EntityType.SHOT

func add_shop_entity(entity) -> void:
	if _entity_manager:
		_entity_manager.register_entity(entity)

func remove_shop_entity(entity) -> void:
	if _entity_manager:
		_entity_manager.unregister_entity(entity)

func get_shop_entities() -> Array:
	if not _entity_manager:
		return []
	return _entity_manager.get_by_type(7)  # EntityType.SHOP

func add_event_entity(entity) -> void:
	if _entity_manager:
		_entity_manager.register_entity(entity)

func remove_event_entity(entity) -> void:
	if _entity_manager:
		_entity_manager.unregister_entity(entity)

func get_event_entities() -> Array:
	if not _entity_manager:
		return []
	return _entity_manager.get_by_type(8)  # EntityType.EVENT

func get_order_self_entities() -> Array:
	if not _entity_manager:
		return []
	return _entity_manager.get_by_type(1)  # EntityType.ORDER_SELF

func get_order_enermy_entities() -> Array:
	if not _entity_manager:
		return []
	return _entity_manager.get_by_type(2)  # EntityType.ORDER_ENEMY

func get_order_self_entity():
	var list = get_order_self_entities()
	return list[0] if not list.is_empty() else null

func get_all_self_entities() -> Array:
	return get_order_self_entities()

func get_entity_by_id(entity_id: String):
	if _entity_manager:
		return _entity_manager.get_by_id(entity_id)
	return null

func get_empty_element_entity():
	for entity in get_element_entities():
		var data_comp = entity.get_component(ComponentNames.DATA)
		if not data_comp or not data_comp.data:
			return entity
	return null

# ==================== 移除所有实体 ====================

func remove_all_entities() -> void:
	if _entity_manager:
		_entity_manager.clear_all()
	_init_flag = false
	clear_items()
	clear_currencies()

# ==================== 步数 ====================

func add_round_total_step(value: int = 1) -> void:
	var s = _get_game_state_service()
	if s: s.add_round_total_step(value)

func get_round_total_step() -> int:
	var s = _get_game_state_service()
	return s.get_round_total_step() if s else 0

func reset_round_total_step() -> void:
	var s = _get_game_state_service()
	if s: s.reset_round_total_step()

func get_step_progress() -> Dictionary:
	var s = _get_game_state_service()
	return s.get_step_progress() if s else {"current": 0, "max": 0, "progress": 0.0}

func update_step() -> void:
	add_round_total_step()
	for entity in get_order_enermy_entities():
		var data_comp = entity.get_component(ComponentNames.DATA)
		if data_comp and data_comp.data:
			var data = data_comp.data
			var step = data.get("step", 0)
			if step and not data.get("isPreAtker", false):
				data["step"] = step - 1

# ==================== 关卡/回合（委托给 GameStateService） ====================

func get_cur_game_type() -> int:
	var s = _get_game_state_service()
	return s.get_cur_game_type() if s else 1

func get_cur_level() -> int:
	var s = _get_game_state_service()
	return s.get_cur_level() if s else 0

func set_cur_level(value: int) -> void:
	var s = _get_game_state_service()
	if s: s.set_cur_level(value)

func to_next_level() -> void:
	var s = _get_game_state_service()
	if s: s.to_next_level()

func reset_round() -> void:
	var s = _get_game_state_service()
	if s: s.reset_round()

func add_round() -> void:
	var s = _get_game_state_service()
	if s: s.add_round()

func get_cur_round_idx() -> int:
	var s = _get_game_state_service()
	return s.get_cur_round_idx() if s else 0

func get_cur_round_meta() -> Dictionary:
	var s = _get_game_state_service()
	return s.get_cur_round_meta() if s else {}

func is_cur_round_finish() -> bool:
	var s = _get_game_state_service()
	return s.is_cur_round_finish() if s else true

func has_alive_self() -> bool:
	for entity in get_order_self_entities():
		var data_comp = entity.get_component(ComponentNames.DATA)
		if data_comp and data_comp.data:
			var hp = data_comp.data.get("hp", 0)
			if hp > 0:
				return true
	return false

func get_self_entity_by_uid(runtime_uid):
	for entity in get_order_self_entities():
		if entity.uid == runtime_uid:
			return entity
	return null

# ==================== Stages ====================

func add_stage(value) -> void:
	var s = _get_game_state_service()
	if s: s.add_stage(value)

func get_stages() -> Array:
	var s = _get_game_state_service()
	return s.get_stages() if s else []

func reset_stages() -> void:
	var s = _get_game_state_service()
	if s: s.reset_stages()

# ==================== UI 临时数据（委托给 GameStateService） ====================

func set_ui_temp_data(difficulty: int, seed: int) -> void:
	var s = _get_game_state_service()
	if s: s.set_ui_temp_data(difficulty, seed)

func get_ui_temp_difficulty() -> int:
	var s = _get_game_state_service()
	return s.get_ui_temp_difficulty() if s else 5

func get_ui_temp_seed() -> int:
	var s = _get_game_state_service()
	return s.get_ui_temp_seed() if s else 0

# ==================== 运行时地图（委托给 GameStateService） ====================

func set_runtime_map(map_model) -> void:
	var s = _get_game_state_service()
	if s: s.set_runtime_map(map_model)

func clear_runtime_map() -> void:
	var s = _get_game_state_service()
	if s: s.clear_runtime_map()

func has_runtime_map() -> bool:
	var s = _get_game_state_service()
	return s.has_runtime_map() if s else false

func get_runtime_map():
	var s = _get_game_state_service()
	return s.get_runtime_map() if s else null

# ==================== 选择数据（委托给 GameStateService） ====================

func set_select_launchers(value: Array) -> void:
	var s = _get_game_state_service()
	if s: s.set_select_launchers(value)

func set_select_order_self_id(value: int) -> void:
	var s = _get_game_state_service()
	if s: s.set_select_order_self_id(value)

func get_selected_character_template_id() -> int:
	var s = _get_game_state_service()
	return s.get_selected_character_template_id() if s else 0

func get_selected_character_template() -> Dictionary:
	var s = _get_game_state_service()
	return s.get_selected_character_template() if s else {}

# ==================== 物品/货币（委托给 InventoryService） ====================

func add_item(item_id: int, count: int = 1) -> void:
	var s = _get_inventory_service()
	if s: s.add_item(item_id, count)

func remove_item(item_id: int, count: int = 1) -> void:
	var s = _get_inventory_service()
	if s: s.remove_item(item_id, count)

func get_item_count(item_id: int) -> int:
	var s = _get_inventory_service()
	return s.get_item_count(item_id) if s else 0

func has_item(item_id: int, count: int = 1) -> bool:
	var s = _get_inventory_service()
	return s.has_item(item_id, count) if s else false

func get_all_items() -> Dictionary:
	var s = _get_inventory_service()
	return s.get_all_items() if s else {}

func clear_items() -> void:
	var s = _get_inventory_service()
	if s: s.clear_items()

func add_currency(currency_id: int, count: int = 1) -> void:
	var s = _get_inventory_service()
	if s: s.add_currency(currency_id, count)

func remove_currency(currency_id: int, count: int = 1) -> void:
	var s = _get_inventory_service()
	if s: s.remove_currency(currency_id, count)

func get_currency_count(currency_id: int) -> int:
	var s = _get_inventory_service()
	return s.get_currency_count(currency_id) if s else 0

func has_enough_currency(currency_id: int, value: int) -> bool:
	var s = _get_inventory_service()
	return s.has_enough_currency(currency_id, value) if s else false

func spend_currency(currency_id: int, value: int) -> bool:
	var s = _get_inventory_service()
	return s.spend_currency(currency_id, value) if s else false

func get_all_currencies() -> Dictionary:
	var s = _get_inventory_service()
	return s.get_all_currencies() if s else {}

func clear_currencies() -> void:
	var s = _get_inventory_service()
	if s: s.clear_currencies()

# ==================== 存档/游戏数据（委托给 PersistenceService） ====================

func get_cur_game_data():
	var s = _get_persistence_service()
	return s.get_cur_game_data() if s else null

func create_new_game_data(record_json = null) -> Dictionary:
	var s = _get_persistence_service()
	if not s:
		return {}
	var gs = _get_game_state_service()
	var launchers = gs.get_select_launchers() if gs else []
	var self_id = gs.get_selected_character_template_id() if gs else 0
	var level = gs.get_cur_level() if gs else 0
	var round_idx = gs.get_cur_round_idx() if gs else 0
	var map = gs.get_runtime_map() if gs else null
	return s.create_new_game_data(record_json, launchers, self_id, level, round_idx, map)

func save_game() -> Dictionary:
	var s = _get_persistence_service()
	var gs = _get_game_state_service()
	var inv = _get_inventory_service()
	if s and gs and inv:
		save_game_to_data()
		return s.save_game(gs, inv)
	return {}

func load_game(save_data: Dictionary) -> bool:
	var s = _get_persistence_service()
	if s:
		remove_all_entities()
		return s.load_game(save_data)
	return false

func save_game_to_data() -> void:
	# 将实体数据同步到存档数据
	var all_types = [
		get_element_entities(),
		get_launcher_entities(),
		get_bullet_entities(),
		get_shot_entities(),
		get_order_entities(),
		get_order_self_entities(),
		get_order_enermy_entities(),
		get_shop_entities(),
		get_event_entities(),
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

# 保留原方法名兼容
func prepare_game_data_for_save() -> void:
	save_game_to_data()

func remove_order_game_data(data: Dictionary) -> void:
	var s = _get_persistence_service()
	if s: s.remove_order_game_data(data)

func get_order_self_data():
	var s = _get_persistence_service()
	return s.get_order_self_data() if s else {}

func get_all_self_datas() -> Array:
	var s = _get_persistence_service()
	return s.get_all_self_datas() if s else []

# ==================== 难度/敌人 ====================

func process_order_defeated(entity) -> void:
	var data_comp = entity.get_component(ComponentNames.DATA)
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

# ==================== 元素工具方法（委托给 ElementService） ====================
# 这些方法已迁移到 core/services/element_service.gd
# 请通过 ClearRoguelikeManager.get_world().element_service 访问
