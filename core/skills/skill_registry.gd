extends Node

# ============================================================
# 技能注册器（替代 SkillRegistry.js）
# ============================================================

static var _registry: Dictionary = {}

static func register_skill(type_str: String, class_ref) -> void:
	_registry[type_str] = class_ref

static func get_skill_class(type_str: String):
	return _registry.get(type_str, null)

static func has_skill(type_str: String) -> bool:
	return _registry.has(type_str)