class_name ElementService

# ============================================================
# 元素服务
# 管理元素相关的工具方法：合并判定、创建元素数据等
# ============================================================

const DEFAULT_BULLET_ID = 8001

# ==================== 元素合并 ====================

func can_element_merge(e1, e2) -> bool:
	var data1 = e1.get_component(ComponentNames.DATA).data if e1.get_component(ComponentNames.DATA) else null
	var data2 = e2.get_component(ComponentNames.DATA).data if e2.get_component(ComponentNames.DATA) else null
	if data1 and data2:
		var meta = MetaConsts.get("elements", {}).get(data2["id"], null)
		return data1["id"] == data2["id"] and meta and meta.get("mergeId", 0) > 0
	return false

func get_element_merge_output_data(entity) -> Dictionary:
	var data_comp = entity.get_component(ComponentNames.DATA)
	if data_comp and data_comp.data:
		var data = data_comp.data
		var meta = MetaConsts.get("elements", {}).get(data["id"], null)
		if meta:
			return {"id": meta["mergeId"], "type": 1}
	return {}

func create_element_data(id: int) -> Dictionary:
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