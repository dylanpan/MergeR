extends BaseBuff

# 减速效果 — 移动计算时，速度 *= (1 - value)
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffEnums.BuffTypes.SLOW
	category = BuffEnums.BuffCategory.ATTRIBUTE_MODIFIER
	trigger_timing = [BuffEnums.BuffTriggerTiming.MOVE_CALCULATE]
	duration = -1

func on_move_calculate(context: BuffContext):
	var speed = context.extra.get("moveSpeed", 1.0)
	context.extra["moveSpeed"] = speed * (1.0 - get_buff_value())