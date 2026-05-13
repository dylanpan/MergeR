extends Node

# ============================================================
# 实体基类（替代 BaseEntity.js）
# ECS 架构中的实体，通过组合组件实现功能
# ============================================================

class_name BaseEntity

var _component_map: Dictionary = {}
var entity_id: String = ""
var uid: int = 0

func _init():
	entity_id = _generate_uuid()

func add_component(c: BaseComponent) -> void:
	if c:
		_component_map[c.comp_name] = c

func get_component_names() -> Array:
	return _component_map.keys()

func get_component(name: String) -> BaseComponent:
	return _component_map.get(name, null)

func remove_component(name: String) -> bool:
	var c = _component_map.get(name, null)
	if c:
		c.dispose()
		_component_map.erase(name)
		return true
	return false

func has_component(name: String) -> bool:
	return _component_map.has(name)

func get_id() -> String:
	return entity_id

func dispose() -> void:
	for c in _component_map.values():
		c.dispose()
	_component_map.clear()

func sync_to_data() -> void:
	var data_comp = get_component(ComponentNames.DATA) as DataComponent
	if not data_comp or data_comp.data.is_empty():
		return
	var buff_comp = get_component(ComponentNames.BUFF) as BuffComponent
	if buff_comp:
		data_comp.data["buffs"] = buff_comp.to_json()

# UUID v4 生成
static func _generate_uuid() -> String:
	var hex_chars = "0123456789abcdef"
	var uuid = ""
	for i in range(36):
		match i:
			8, 13, 18, 23:
				uuid += "-"
			14:
				uuid += "4"
			19:
				uuid += hex_chars[3 + randi() % 4]
			_:
				uuid += hex_chars[randi() % 16]
	return uuid