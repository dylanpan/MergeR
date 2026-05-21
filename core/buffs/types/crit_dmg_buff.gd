extends BaseBuff

# 暴击伤害+50% — 暴击结算时，暴击伤害倍率 += value
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffEnums.BuffTypes.CRIT_DMG
	category = BuffEnums.BuffCategory.ATTRIBUTE_MODIFIER
	trigger_timing = [BuffEnums.BuffTriggerTiming.CRIT_SETTLE]
	duration = -1

func on_crit_settle(context: BuffContext):
	var crit_dmg = context.extra.get("critDamageMultiplier", 1.0)
	context.extra["critDamageMultiplier"] = crit_dmg + get_buff_value()