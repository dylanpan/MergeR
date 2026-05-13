class_name EntityQuery

# ============================================================
# 实体查询器
# 链式 API: World.query().with("Data").with("Buff").all()
# ============================================================

var _entity_pool: Array = []
var _include_components: Array = []
var _exclude_components: Array = []

func _init(entities: Array):
	_entity_pool = entities.duplicate()

func with(comp_name: String) -> EntityQuery:
	_include_components.append(comp_name)
	return self

func without(comp_name: String) -> EntityQuery:
	_exclude_components.append(comp_name)
	return self

func all() -> Array:
	var result: Array = []
	for entity in _entity_pool:
		if not entity or not entity.has_method("get_component"):
			continue
		var matched = true
		for comp_name in _include_components:
			if not entity.has_component(comp_name):
				matched = false
				break
		if not matched:
			continue
		for comp_name in _exclude_components:
			if entity.has_component(comp_name):
				matched = false
				break
		if matched:
			result.append(entity)
	return result

func first():
	var results = all()
	return results[0] if not results.is_empty() else null