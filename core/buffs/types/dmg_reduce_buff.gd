extends BaseBuff

# 受到伤害-10% — 受击时伤害 *= (1 - value)
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffEnums.BuffTypes.DMG_REDUCE
	category = BuffEnums.BuffCategory.ATTRIBUTE_MODIFIER
	trigger_timing = [BuffEnums.BuffTriggerTiming.HURT]
	duration = -1

func on_hurt(context: BuffContext):
	var dmg = context.extra.get("modifiedValue", 0)
	if dmg > 0:
		context.extra["modifiedValue"] = dmg * (1.0 - get_buff_value())