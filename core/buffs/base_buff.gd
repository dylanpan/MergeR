extends Node

# ============================================================
# Buff 基类（替代 BaseBuff.js）
# 所有具体 Buff 类型都需要继承此类
# ============================================================

class_name BaseBuff

# 唯一标识
var id: String = ""
# 效果类型
var type: int = BuffEnums.BuffTypes.NONE
# 效果值
var value: float = 0.0
# 持续回合数 (-1 永久)
var duration: int = -1
# 剩余回合数
var remaining_duration: int = -1
# 叠加层数
var stacks: int = 1
# 最大叠加层数
var max_stacks: int = 99
# 来源
var source = null
# 是否已过期
var is_expired: bool = false
# 是否已激活
var is_active: bool = false
# 分类
var category: int = BuffEnums.BuffCategory.EMPTY
# 触发时机列表
var trigger_timing: Array = []

func _init(buff_data: Dictionary = {}):
	id = buff_data.get("id", "buff_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 10000))
	type = buff_data.get("type", BuffEnums.BuffTypes.NONE)
	value = buff_data.get("value", 0.0)
	duration = buff_data.get("duration", -1)
	remaining_duration = buff_data.get("remainingDuration", duration)
	stacks = buff_data.get("stacks", 1)
	max_stacks = buff_data.get("maxStacks", 99)
	source = buff_data.get("source", null)
	is_expired = false
	is_active = false
	category = BuffEnums.BuffCategory.EMPTY
	trigger_timing = []

func apply(context: BuffContext) -> void:
	is_active = true

func remove(context: BuffContext) -> void:
	is_active = false

func on_round_start(context: BuffContext) -> void:
	pass

func on_round_end(context: BuffContext) -> void:
	if duration > 0:
		remaining_duration -= 1
		if remaining_duration <= 0:
			is_expired = true

func on_attack_check(context: BuffContext) -> void:
	pass

func on_damage_calculate(context: BuffContext) -> void:
	pass

func on_crit_settle(context: BuffContext) -> void:
	pass

func on_hurt(context: BuffContext) -> void:
	pass

func on_bullet_create(context: BuffContext) -> void:
	pass

func on_move_calculate(context: BuffContext) -> void:
	pass

func on_attack_end(context: BuffContext) -> void:
	pass

func on_damage_settle(context: BuffContext) -> void:
	pass

func on_element_check(context: BuffContext) -> void:
	pass

func on_action_phase(context: BuffContext) -> void:
	pass

func add_stacks(p_stacks: int = 1) -> void:
	stacks = min(stacks + p_stacks, max_stacks)

func remove_stacks(p_stacks: int = 1) -> void:
	stacks = max(stacks - p_stacks, 0)
	if stacks <= 0:
		is_expired = true

func get_buff_value() -> float:
	return value * stacks

func to_json() -> Dictionary:
	return {
		"id": id,
		"type": type,
		"value": value,
		"duration": duration,
		"remainingDuration": remaining_duration,
		"stacks": stacks,
		"maxStacks": max_stacks,
		"source": source,
		"isExpired": is_expired,
		"isActive": is_active,
	}