extends Node

# ============================================================
# Buff 执行上下文（替代 BuffContext.js）
# 封装 Buff 的执行环境，包括目标实体、来源、数值等信息
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

func _init(p_entity = null, p_source = null, p_buff_data: Dictionary = {}):
	entity = p_entity
	source = p_source
	buff_data = p_buff_data

# 获取 Buff 数值
func get_value() -> float:
	return buff_data.get("value", 0.0)

# 获取 Buff 层数
func get_stack() -> int:
	return buff_data.get("stack", 1)

# 获取 Buff 剩余回合数
func get_remaining_turns() -> int:
	return buff_data.get("remainingTurns", -1)