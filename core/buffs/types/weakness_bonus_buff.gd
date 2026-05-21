extends BaseBuff

# 克制伤害加成Buff — 克制目标时伤害额外提升
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffEnums.BuffTypes.WEAKNESS_BONUS
	category = BuffEnums.BuffCategory.ATTRIBUTE_MODIFIER
	trigger_timing = [BuffEnums.BuffTriggerTiming.DAMAGE_CALCULATE]
	duration = -1

func on_damage_calculate(context: BuffContext):
	if context.extra.get("isWeakness", false):
		var dmg_mult = context.extra.get("damageMultiplier", 1.0)
		context.extra["damageMultiplier"] = dmg_mult * (1.0 + get_buff_value())