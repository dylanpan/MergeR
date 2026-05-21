extends BaseBuff

# 暴击率+10% — 攻击判定时暴击率 += value
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffEnums.BuffTypes.CRIT_RATE
	category = BuffEnums.BuffCategory.ATTRIBUTE_MODIFIER
	trigger_timing = [BuffEnums.BuffTriggerTiming.ATTACK_CHECK]
	duration = -1

func on_attack_check(context: BuffContext):
	var crit_rate = context.extra.get("critRate", 0.0)
	context.extra["critRate"] = crit_rate + get_buff_value()