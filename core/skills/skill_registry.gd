extends Node

# ============================================================
# 技能注册器（替代 SkillRegistry.js）
# ============================================================

static var _registry: Dictionary = {}

static func register_skill(type_str: String, class_ref) -> void:
	_registry[type_str] = class_ref

static func get_skill_class(type_str: String):
	return _registry.get(type_str, null)

# 创建技能实例（替代 JS createSkill）
static func create_skill(type_str: String, skill_data: Dictionary = {}) -> BaseSkill:
	var SkillClass = _registry.get(type_str, null)
	if SkillClass == null:
		push_error("Unknown skill type: ", type_str)
		return null
	return SkillClass.new(skill_data)

static func has_skill(type_str: String) -> bool:
	return _registry.has(type_str)

# 获取所有已注册技能类型（替代 JS getRegisteredSkillTypes）
static func get_registered_skill_types() -> Array:
	return _registry.keys()
