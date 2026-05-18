extends Node

# ============================================================
# Buff 执行上下文（替代 BuffContext.js）
# 封装 Buff 的执行环境，包括目标实体、来源、数值等信息
# 支持值修正链、短路控制和战斗数据透传
# ============================================================

class_name BuffContext

# 被作用的实体
var entity
# Buff 来源（可选的实体引用）
var source
# Buff 原始数据
var buff_data: Dictionary = {}
# 触发时机
var trigger_timing: int = -1
# 额外参数
var extra: Dictionary = {}

# 值修正系统
var base_value: float = 0.0     # 原始数值
var modified_value: float = 0.0  # 修正后数值

# 战斗数据透传
var attack_data: Dictionary = {}
var damage_data: Dictionary = {}
var bullet_data: Dictionary = {}

# 短路控制
var _cancelled: bool = false

func _init(p_entity = null, p_source = null, p_buff_data: Dictionary = {}):
	entity = p_entity
	source = p_source
	buff_data = p_buff_data
	base_value = p_buff_data.get("value", 0.0)
	modified_value = base_value

# 取消后续 Buff 执行
func cancel() -> void:
	_cancelled = true

# 是否已被取消
func is_cancelled() -> bool:
	return _cancelled

# 设置修正值
func set_value(value: float) -> void:
	modified_value = value

# 累乘修正值
func multiply_value(factor: float) -> void:
	modified_value *= factor

# 累加修正值
func add_value(delta: float) -> void:
	modified_value += delta

# 获取 Buff 数值
func get_value() -> float:
	return buff_data.get("value", 0.0)

# 获取 Buff 层数
func get_stack() -> int:
	return buff_data.get("stack", 1)

# 获取 Buff 剩余回合数
func get_remaining_turns() -> int:
	return buff_data.get("remainingTurns", -1)

# 序列化
func to_json() -> Dictionary:
	return {
		"baseValue": base_value,
		"modifiedValue": modified_value,
		"cancelled": _cancelled,
		"source": source.get_id() if source and source.has_method("get_id") else "",
		"target": entity.get_id() if entity and entity.has_method("get_id") else "",
		"timing": trigger_timing,
	}
