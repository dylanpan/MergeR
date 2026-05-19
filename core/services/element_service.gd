class_name ElementService

# ============================================================
# 元素服务
# 管理元素相关的工具方法：合并判定、创建元素数据等
# ============================================================

const DEFAULT_BULLET_ID = 8001

# ==================== 元素合并 ====================

func can_element_merge(e1, e2, world: World = null) -> bool:
	var data1 = e1.get_component(ComponentNames.DATA).data if e1.get_component(ComponentNames.DATA) else null
	var data2 = e2.get_component(ComponentNames.DATA).data if e2.get_component(ComponentNames.DATA) else null
	if data1 and data2:
		var meta = _get_element_meta(data2["id"], world)
		return data1["id"] == data2["id"] and meta and meta.get("mergeId", 0) > 0
	return false

func get_element_merge_output_data(entity, world: World = null) -> Dictionary:
	var data_comp = entity.get_component(ComponentNames.DATA)
	if data_comp and data_comp.data:
		var data = data_comp.data
		var meta = _get_element_meta(data["id"], world)
		if meta:
			return {"id": meta.get("mergeId", 0), "type": 1}
	return {}

func create_element_data(id: int, world: World = null) -> Dictionary:
	var config = _get_config_service(world)
	if config:
		var element_meta = config.get_launcher(id)
		if not element_meta.is_empty():
			return _build_from_launcher(element_meta, config)
	
	# Fallback: try config service via global manager
	config = _get_config_service(null)
	if config:
		var element_meta = config.get_launcher(id)
		if not element_meta.is_empty():
			return _build_from_launcher(element_meta, config)
		var fallback_meta = config.get_element(DEFAULT_BULLET_ID)
		if not fallback_meta.is_empty():
			return {
				"id": fallback_meta.get("id", DEFAULT_BULLET_ID),
				"type": fallback_meta.get("type", 1),
				"atk": fallback_meta.get("atk", 0),
				"distance": fallback_meta.get("distance", fallback_meta.get("range", 0)),
				"cover": fallback_meta.get("cover", 0),
				"elementType": fallback_meta.get("elementType", 0),
			}
	
	return {"id": DEFAULT_BULLET_ID, "type": 1, "elementType": 0}

func _build_from_launcher(launcher_meta: Dictionary, config) -> Dictionary:
	var chosen_element_type = _get_element_type(launcher_meta)
	var TYPE_TO_BULLET = {
		1: 1001, 2: 2001, 3: 4001, 4: 6001, 0: 8001,
	}
	var bullet_id = TYPE_TO_BULLET.get(chosen_element_type, DEFAULT_BULLET_ID)
	var bullet_meta = config.get_element(bullet_id)
	return _build_meta_data(bullet_meta, bullet_id, chosen_element_type)

func _build_bullet_data(bullet_id: int, chosen_element_type: int) -> Dictionary:
	var config = _get_config_service(null)
	var meta = config.get_element(bullet_id) if config else {}
	if meta.is_empty() and config:
		meta = config.get_element(DEFAULT_BULLET_ID)
	return _build_meta_data(meta, bullet_id, chosen_element_type)

func _build_meta_data(meta, bullet_id: int, chosen_element_type: int) -> Dictionary:
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

func _get_element_meta(id: int, world: World = null) -> Dictionary:
	var config = _get_config_service(world)
	if config:
		return config.get_element(id)
	return {}

func _get_config_service(world: World = null):
	if world and world.config_service:
		return world.config_service
	if ClearRoguelikeManager.get_world():
		return ClearRoguelikeManager.get_world().config_service
	return null

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