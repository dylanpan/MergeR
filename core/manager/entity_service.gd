class_name EntityService

# ============================================================
# 实体服务
# 封装 EntityManager，提供便捷的实体 CRUD API
# 逐步替代 WorldDataManager 中的实体管理方法
# ============================================================

const EntityType = preload("res://core/entity_manager/entity_type.gd")

var _em: EntityManager = null

func _init(em: EntityManager):
	_em = em

# ==================== 注册/注销 ====================

func register(entity) -> void:
	_em.register_entity(entity)

func unregister(entity) -> void:
	_em.unregister_entity(entity)

func dispose(entity) -> void:
	_em.dispose_entity(entity)

# ==================== 查询便利方法 ====================

func get_by_id(entity_id: String):
	return _em.get_by_id(entity_id)

func get_order_self() -> Array:
	return _em.get_by_type(EntityType.ORDER_SELF)

func get_order_enemy() -> Array:
	return _em.get_by_type(EntityType.ORDER_ENEMY)

func get_order_all() -> Array:
	var result = _em.get_by_type(EntityType.ORDER_SELF)
	result.append_array(_em.get_by_type(EntityType.ORDER_ENEMY))
	return result

func get_elements() -> Array:
	return _em.get_by_type(EntityType.ELEMENT)

func get_launchers() -> Array:
	return _em.get_by_type(EntityType.LAUNCHER)

func get_bullets() -> Array:
	return _em.get_by_type(EntityType.BULLET)

func get_shots() -> Array:
	return _em.get_by_type(EntityType.SHOT)

func get_shops() -> Array:
	return _em.get_by_type(EntityType.SHOP)

func get_events() -> Array:
	return _em.get_by_type(EntityType.EVENT)

# ==================== 高级查询 ====================

func find_alive_self() -> Array:
	var result = []
	for entity in get_order_self():
		var data_comp = entity.get_component(ComponentNames.DATA)
		if data_comp and data_comp.data:
			var hp = data_comp.data.get("hp", 0)
			if hp > 0:
				result.append(entity)
	return result

func has_alive_self() -> bool:
	return not find_alive_self().is_empty()

func get_order_self_entity():
	var list = get_order_self()
	return list[0] if not list.is_empty() else null

func get_self_entity_by_uid(runtime_uid: int):
	for entity in get_order_self():
		if entity.uid == runtime_uid:
			return entity
	return null

func get_empty_element():
	for entity in get_elements():
		var data_comp = entity.get_component(ComponentNames.DATA)
		if not data_comp or not data_comp.data:
			return entity
	return null

# ==================== 清理 ====================

func clear_all() -> void:
	_em.clear_all()