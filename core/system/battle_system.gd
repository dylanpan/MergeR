extends BaseSystem

# ============================================================
# 战斗系统（替代 BattleSystem.js）
# 负责战斗伤害计算、元素克制判定
# ============================================================

func _init():
	pass

func dispose():
	pass

func update(dt: float) -> void:
	if not _world:
		return
	var stages = _world.game_state_service.get_stages()
	for stage in stages:
		_do_stage(stage)
	_update_boss_abilities(dt)
	_world.game_state_service.reset_stages()

func _do_stage(stage: int) -> void:
	match stage:
		GameConsts.StageSelfBattle:
			var order_self = _world.entity_service.get_order_self()
			var order_enermy = _world.entity_service.get_order_enemy()
			_do_battle(order_self, order_enermy, true)
			GlobalEventBus.event_battle_update.emit({"type": "enemy_hit"})
			_reset_battle_flag(order_self)
			GlobalEventBus.event_battle_update.emit({"type": "self_atk"})
		
		GameConsts.StageEnermyBattle:
			var order_self = _world.entity_service.get_order_self()
			var order_enermy = _world.entity_service.get_order_enemy()
			_do_battle(order_enermy, order_self, false)
			GlobalEventBus.event_battle_update.emit({"type": "self_hit"})
			_reset_battle_flag(order_enermy)
			GlobalEventBus.event_battle_update.emit({"type": "enemy_atk"})

func _do_battle(atk_entities: Array, def_entities: Array, is_left: bool = true) -> void:
	for atk_entity in atk_entities:
		var atk_data_comp = atk_entity.get_component(ComponentNames.DATA) as DataComponent
		if not atk_data_comp or not atk_data_comp.data.get("isAtker", false):
			continue
		var atk_data = atk_data_comp.data
		var bullets = atk_data.get("bullets", [])
		if bullets.is_empty():
			continue
		
		var cannot_atk = false
		for bullet_id in bullets:
			var meta = _world.config_service.get_element(bullet_id)
			if meta.is_empty():
				continue
			var distance = meta.get("distance", 1)
			var cover = meta.get("cover", 0)
			var base_atk = meta.get("atk", 0)
			var element_type = meta.get("elementType", 0)
			var weakness_multiplier = meta.get("weaknessMultiplier", 1.0)
			
			for k in range(def_entities.size() - 1, -1, -1):
				var step = is_left if (atk_entities.size() - 1 - (atk_entities.find(atk_entity) - k)) else (def_entities.size() - 1 + (atk_entities.find(atk_entity) - k))
				var hit = false
				if cover == 0:
					if step == distance - 1:
						hit = true
				else:
					if step < distance:
						hit = true
				
				if hit:
					var def_entity = def_entities[k]
					var def_data_comp = def_entity.get_component(ComponentNames.DATA) as DataComponent
					if not def_data_comp:
						continue
					var def_data = def_data_comp.data
					var def_elem_type = def_data.get("elementType", 0)
					
					var is_weakness = _check_weakness_match(element_type, def_elem_type)
					var is_resistance = _check_resistance_match(element_type, def_elem_type)
					
					var total_atk = atk_data.get("atk", 0) + base_atk
					var def_factor = 100.0 / (100.0 + def_data.get("def", 0))
					var final_atk = total_atk * def_factor
					
					if is_weakness:
						final_atk *= weakness_multiplier
					elif is_resistance:
						final_atk *= 0.5
					
					_do_hit(def_entity, final_atk, is_weakness, is_resistance)
				
				if step >= distance:
					cannot_atk = true
		
		if cannot_atk:
			_do_change_pre_atker(atk_entity)
		else:
			_do_reset_step(atk_entity)

func _do_hit(entity, atk: float, is_weakness: bool, is_resistance: bool) -> void:
	var data_comp = entity.get_component(ComponentNames.DATA) as DataComponent
	if not data_comp:
		return
	var data = data_comp.data
	data["hp"] = data.get("hp", 0) - atk
	
	GlobalEventBus.event_battle_update.emit({
		"type": "damage",
		"entity": entity,
		"damage": atk,
		"is_weakness": is_weakness,
		"is_resistance": is_resistance
	})
	
	if data.get("hp", 0) <= 0 and _world:
		_process_order_defeated(entity)

func _process_order_defeated(entity) -> void:
	if not _world:
		return
	var data_comp = entity.get_component(ComponentNames.DATA)
	if not data_comp or not data_comp.data:
		return
	var data = data_comp.data
	if data.get("type") == GameConsts.OrderType_Enermy and data.get("hp", 0) <= 0:
		var order_meta = _world.config_service.get_enemy(data["id"])
		var drop_items = order_meta.get("dropItems", [])
		for drop_item in drop_items:
			var chance = drop_item.get("chance", 0.0)
			var item_id = drop_item.get("itemId", 0)
			var count = drop_item.get("count", 1)
			if randf() < chance:
				_world.inventory_service.add_item(item_id, count)

func _do_reset_step(entity) -> void:
	var data_comp = entity.get_component(ComponentNames.DATA) as DataComponent
	if not data_comp:
		return
	var data = data_comp.data
	if data.get("type") == GameConsts.OrderType_Enermy:
		var order_meta = _world.config_service.get_enemy(data.get("id", 0))
		data["step"] = order_meta.get("step", 0)

func _do_change_pre_atker(entity) -> void:
	var data_comp = entity.get_component(ComponentNames.DATA) as DataComponent
	if not data_comp:
		return
	var data = data_comp.data
	if data.get("type") == GameConsts.OrderType_Enermy:
		data["isAtker"] = 0
		data["isPreAtker"] = 1

func _reset_battle_flag(entities: Array) -> void:
	for entity in entities:
		var data_comp = entity.get_component(ComponentNames.DATA) as DataComponent
		if not data_comp:
			continue
		var data = data_comp.data
		if data.get("isAtker", false):
			data["bullets"] = []
			data["isAtker"] = 0

func _check_weakness_match(atk_elem: int, def_elem: int) -> bool:
	return _world.config_service.is_weakness(atk_elem, def_elem)

func _check_resistance_match(atk_elem: int, def_elem: int) -> bool:
	return _world.config_service.is_resistance(atk_elem, def_elem)

func _update_boss_abilities(dt: float) -> void:
	if not _world:
		return
	var enermy_entities = _world.entity_service.get_order_enemy()
	for boss_entity in enermy_entities:
		var pm = boss_entity.get_component(ComponentNames.PHASE_MANAGER) as PhaseManagerComponent
		if pm:
			var data_comp = boss_entity.get_component(ComponentNames.DATA) as DataComponent
			if data_comp:
				var hp = data_comp.data.get("hp", 0)
				var max_hp = data_comp.data.get("maxHp", hp)
				var ratio = float(hp) / float(max_hp) if max_hp > 0 else 0.0
				pm.update_phase(dt, ratio)