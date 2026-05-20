extends Node
class_name BuffRegistry

# ============================================================
# Buff 注册器（替代 BuffRegistry.js）
# 管理所有 Buff 类型的注册和查找
# ============================================================

static var _registry: Dictionary = {}

static func register_buff(type_str: String, class_ref) -> void:
	_registry[type_str] = class_ref

static func get_buff_class(type_str: String):
	return _registry.get(type_str, null)

static func has_buff(type_str: String) -> bool:
	return _registry.has(type_str)

static func get_all_buff_types() -> Array:
	return _registry.keys()