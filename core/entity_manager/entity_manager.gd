class_name EntityManager

# ============================================================
# 实体管理器
# 集中管理所有实体的注册、查询、生命周期
# 替代 WorldDataManager 中的实体列表管理职责
# ============================================================

const EntityType = preload("res://core/entity_manager/entity_type.gd")

# O(1) 实体 ID 映射表
var _entity_map: Dictionary = {}

# 按类型分组的实体列表
var _entities_by_type: Dictionary = {}

# 按组件标签索引（可选优化）
var _entities_by_component: Dictionary = {}

func _init():
	_reset()

# ==================== 注册 ====================

func register_entity(entity) -> void:
	if not entity or not entity.has_method("get_id"):
		return
	var entity_id = entity.get_id()
	_entity_map[entity_id] = entity

	# 使用实体自身的 get_entity_type() 方法分类
	var type_val = _resolve_entity_type(entity)
	if type_val != EntityType.UNKNOWN:
		if not _entities_by_type.has(type_val):
			_entities_by_type[type_val] = []
		_entities_by_type[type_val].append(entity)

	# 按组件索引
	if entity.has_method("get_component_names"):
		for comp_name in entity.get_component_names():
			if not _entities_by_component.has(comp_name):
				_entities_by_component[comp_name] = []
			_entities_by_component[comp_name].append(entity)

func unregister_entity(entity) -> void:
	if not entity or not entity.has_method("get_id"):
		return
	var entity_id = entity.get_id()
	_entity_map.erase(entity_id)

	# 从类型列表移除
	var type_val = _resolve_entity_type(entity)
	if type_val != EntityType.UNKNOWN and _entities_by_type.has(type_val):
		var list = _entities_by_type[type_val]
		var idx = list.find(entity)
		if idx != -1:
			list.remove_at(idx)

	# 从组件索引移除
	if entity.has_method("get_component_names"):
		for comp_name in entity.get_component_names():
			if _entities_by_component.has(comp_name):
				var list = _entities_by_component[comp_name]
				var idx = list.find(entity)
				if idx != -1:
					list.remove_at(idx)

# ==================== 查询 ====================

func get_by_id(entity_id: String):
	return _entity_map.get(entity_id, null)

func get_by_type(type_val: int) -> Array:
	return _entities_by_type.get(type_val, []).duplicate()

func get_all() -> Array:
	return _entity_map.values().duplicate()

func query() -> EntityQuery:
	return EntityQuery.new(_entity_map.values())

func query_type(type_val: int) -> EntityQuery:
	return EntityQuery.new(get_by_type(type_val))

func count_by_type(type_val: int) -> int:
	var list = _entities_by_type.get(type_val, [])
	return list.size()

# ==================== 生命周期 ====================

func clear_all() -> void:
	for entity in _entity_map.values():
		if entity.has_method("dispose"):
			entity.dispose()
	_reset()

func dispose_entity(entity) -> void:
	unregister_entity(entity)
	if entity.has_method("dispose"):
		entity.dispose()

# ==================== 内部方法 ====================

func _resolve_entity_type(entity) -> int:
	# 优先使用实体自身的 get_entity_type() 方法（最安全，不依赖字符串匹配）
	if entity.has_method("get_entity_type"):
		var type_val = entity.get_entity_type()
		if type_val != EntityType.UNKNOWN:
			return type_val
	
	# 降级：通过 DataComponent 中的 type 字段判断（用于 Order 类型）
	if entity.has_method("get_component"):
		var data_comp = entity.get_component(ComponentNames.DATA)
		if data_comp and data_comp.data:
			var type_val = data_comp.data.get("type", 0)
			if type_val == GameConsts.OrderType_Self:
				return EntityType.ORDER_SELF
			elif type_val == GameConsts.OrderType_Enermy:
				return EntityType.ORDER_ENEMY
	
	return EntityType.UNKNOWN

func _reset() -> void:
	_entity_map.clear()
	_entities_by_type.clear()
	_entities_by_component.clear()
	_entities_by_type[EntityType.UNKNOWN] = []
	_entities_by_type[EntityType.ORDER_SELF] = []
	_entities_by_type[EntityType.ORDER_ENEMY] = []
	_entities_by_type[EntityType.ELEMENT] = []
	_entities_by_type[EntityType.LAUNCHER] = []
	_entities_by_type[EntityType.BULLET] = []
	_entities_by_type[EntityType.SHOT] = []
	_entities_by_type[EntityType.SHOP] = []
	_entities_by_type[EntityType.EVENT] = []
	_entities_by_type[EntityType.REST] = []
