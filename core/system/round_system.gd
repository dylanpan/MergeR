extends BaseSystem

# ============================================================
# 回合系统（替代 RoundSystem.js - 410行）
# 管理游戏回合流程、实体生成、胜负判定
# ============================================================

func _init():
	pass

func dispose():
	pass

func update(dt: float) -> void:
	var state = _update_after_battle()
	match state:
		GameConsts.RoundState_Normal:
			pass
		GameConsts.RoundState_GameStart:
			_game_start()
		GameConsts.RoundState_GameOver:
			_game_over()
		GameConsts.RoundState_RoundOver:
			_add_new_order_enermy_entities()
		GameConsts.RoundState_MaxStep:
			_add_new_order_enermy_entities()
		GameConsts.RoundState_LevelOver:
			_game_round_over()

func _update_after_battle() -> int:
	if not _world:
		return GameConsts.RoundState_Normal
	
	var state = GameConsts.RoundState_Normal
	
	if not _world.game_state_service.get_init_flag():
		return GameConsts.RoundState_GameStart
	
	# 步数限制检测
	var step_progress = _world.game_state_service.get_step_progress()
	if step_progress.get("max", 0) > 0 and step_progress.get("current", 0) >= step_progress.get("max", 0):
		GlobalEventBus.event_ui_update_refresh_warning.emit({
			"type": "step_limit",
			"message": "步数已达上限，即将刷新订单！"
		})
		return GameConsts.RoundState_MaxStep
	
	# 检测己方单位
	var self_entities = _world.entity_service.get_order_self()
	var self_finished = []
	for entity in self_entities:
		var data_comp = entity.get_component(ComponentNames.DATA) as DataComponent
		if not data_comp:
			continue
		var data = data_comp.data
		if data.get("hp", 0) <= 0:
			entity.dispose()
			self_finished.append(entity)
		elif data.get("isPreAtker", 0) == 1:
			if data.get("hp", 0) > 0:
				data["isPreAtker"] = 0
	
	for entity in self_finished:
		_world.entity_manager.unregister_entity(entity)
	
	if self_finished.size() >= self_entities.size():
		return GameConsts.RoundState_GameOver
	
	# 检测敌方单位
	var enermy_entities = _world.entity_service.get_order_enemy()
	var enermy_finished = []
	for entity in enermy_entities:
		var data_comp = entity.get_component(ComponentNames.DATA) as DataComponent
		if not data_comp:
			continue
		var data = data_comp.data
		if data.get("hp", 0) <= 0:
			entity.dispose()
			enermy_finished.append(entity)
		elif data.get("isPreAtker", 0) == 1:
			if data.get("hp", 0) > 0:
				data["isPreAtker"] = 0
	
	for entity in enermy_finished:
		_world.entity_manager.unregister_entity(entity)
	
	if enermy_finished.size() >= enermy_entities.size() and not enermy_entities.is_empty():
		if _world.game_state_service.is_cur_round_finish():
			return GameConsts.RoundState_LevelOver
		else:
			return GameConsts.RoundState_RoundOver
	
	return state

func _game_start() -> void:
	if not _world:
		return
	var game_data = _world.persistence_service.create_new_game_data(
		null,
		_world.game_state_service.get_select_launchers(),
		_world.game_state_service.get_selected_character_template_id(),
		_world.game_state_service.get_cur_level(),
		_world.game_state_service.get_cur_round_idx(),
		_world.game_state_service.get_runtime_map()
	)
	_add_element_entities(game_data)
	_add_launcher_entities(game_data)
	_add_bullet_entities(game_data)
	_add_order_entities(game_data)
	_add_shot_entities()
	
	_world.game_state_service.set_init_flag(true)
	GlobalEventBus.event_ui_update_step.emit(_world.game_state_service.get_step_progress())

func _add_element_entities(game_data) -> void:
	if not _world:
		return
	var ui_root = _world.ui_root_service.get_element_ui_root()
	if not ui_root:
		return
	var col = game_data.col if game_data else 7
	var row = game_data.row if game_data else 5
	for i in range(col):
		for j in range(row):
			var entity = ElementEntity.new(i, j, ui_root, GameConsts.AreaId_Element)
			var key = str(i) + "_" + str(j)
			var element_data = game_data.elements.get(key, {}) if game_data else {}
			if not element_data.is_empty():
				entity.init(element_data)
			_world.entity_manager.register_entity(entity)

func _add_launcher_entities(game_data) -> void:
	if not _world:
		return
	var ui_root = _world.ui_root_service.get_launcher_ui_root()
	if not ui_root:
		return
	var lcol = game_data.lcol if game_data else 7
	var lrow = game_data.lrow if game_data else 1
	for i in range(lcol):
		for j in range(lrow):
			var entity = LauncherEntity.new(i, j, ui_root, GameConsts.AreaId_Launcher)
			var key = str(i) + "_" + str(j)
			var launcher_data = game_data.launchers.get(key, {}) if game_data else {}
			if not launcher_data.is_empty():
				var data_comp = entity.get_component(ComponentNames.DATA) as DataComponent
				if data_comp:
					data_comp.init(launcher_data)
			_world.entity_manager.register_entity(entity)

func _add_bullet_entities(game_data) -> void:
	if not _world:
		return
	var launchers = _world.entity_service.get_launchers()
	for launcher in launchers:
		var data_comp = launcher.get_component(ComponentNames.DATA) as DataComponent
		if data_comp and not data_comp.data.is_empty():
			var elem_data = _world.element_service.create_element_data(data_comp.data.get("id", 0))
			var bullet_entity = BaseEntity.new()
			var bullet_data_comp = DataComponent.new(elem_data)
			bullet_entity.add_component(bullet_data_comp)
			_world.entity_manager.register_entity(bullet_entity)

func _add_order_entities(game_data) -> void:
	if not _world:
		return
	# 己方单位
	var self_datas = game_data.orderSelf if game_data else []
	for data in self_datas:
		var entity = OrderSelfEntity.new(data)
		_world.entity_manager.register_entity(entity)
	
	# 敌方单位
	var enermy_datas = game_data.orderEnermy if game_data else []
	for data in enermy_datas:
		var entity = OrderEnermyEntity.new(data)
		_world.entity_manager.register_entity(entity)

func _add_shot_entities() -> void:
	# 简化：攻击槽由 UI 层创建
	pass

func _add_new_order_enermy_entities() -> void:
	if not _world:
		return
	_world.game_state_service.add_round()
	var round_meta = _world.game_state_service.get_cur_round_meta()
	if not round_meta.is_empty():
		var enermy_datas = WorldDataManager.create_order_enermy_data(round_meta)
		for data in enermy_datas:
			var entity = OrderEnermyEntity.new(data)
			_world.entity_manager.register_entity(entity)
	_world.game_state_service.reset_round_total_step()
	GlobalEventBus.event_ui_update_step.emit(_world.game_state_service.get_step_progress())

func _game_over() -> void:
	if not _world:
		return
	# 保存游戏结束前的状态
	WorldDataManager.prepare_game_data_for_save()
	var save_data = WorldDataManager.save_game()
	if not save_data.is_empty():
		var json = JSON.stringify(save_data)
		if not json.is_empty():
			var config = ConfigFile.new()
			config.set_value("save", "clear_roguelike_last", json)
			config.save("user://clear_roguelike_save.cfg")
	
	GlobalEventBus.event_update_game_over.emit()

func _game_round_over() -> void:
	if not _world:
		return
	_world.game_state_service.to_next_level()
	
	var cur_level = _world.game_state_service.get_cur_level()
	var level_meta = MetaConsts.get("gameLevels", {}).get(cur_level, {})
	if level_meta.is_empty():
		GlobalEventBus.event_round_new_level_start.emit()
		return
	
	# 检查商店配置
	var shops = level_meta.get("shops", [])
	if not shops.is_empty():
		for shop_id in shops:
			GlobalEventBus.event_shop_open.emit(shop_id, MetaConsts.get("gameShops", {}).get(shop_id, {}))
		return
	
	# 检查事件配置
	var events = level_meta.get("events", [])
	if not events.is_empty():
		for event_id in events:
			GlobalEventBus.event_event_open.emit(event_id, MetaConsts.get("gameEvents", {}).get(event_id, {}))
		return
	
	# 检查休息节点配置
	var rests = level_meta.get("rests", [])
	if not rests.is_empty():
		for rest_id in rests:
			GlobalEventBus.event_rest_open.emit(rest_id, MetaConsts.get("gameRests", {}).get(rest_id, {}))
		return
	
	# 无特殊节点，继续下一关
	match cur_level:
		-1:
			pass
		-2:
			GlobalEventBus.event_update_game_win.emit()
		_:
			GlobalEventBus.event_round_new_level_start.emit()