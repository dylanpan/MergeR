extends BaseBuff

# 无视防御5% — 伤害计算时，目标防御 *= (1 - value)
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffTypes.DEF_IGNORE
	category = BuffCategory.ATTRIBUTE_MODIFIER
	trigger_timing = [BuffTriggerTiming.DAMAGE_CALCULATE]
	duration = -1

func on_damage_calculate(context: BuffContext):
	var target_def = context.extra.get("targetDefense", 0)
	context.extra["targetDefense"] = target_def * (1.0 - get_buff_value())