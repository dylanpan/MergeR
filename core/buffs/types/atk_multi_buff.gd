extends BaseBuff

# 攻击倍率Buff — 所有伤害按比例提升
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffTypes.ATK_MULTI
	category = BuffCategory.ATTRIBUTE_MODIFIER
	trigger_timing = [BuffTriggerTiming.DAMAGE_CALCULATE]
	duration = -1

func on_damage_calculate(context: BuffContext):
	var final_damage = context.extra.get("finalDamage", 0)
	if final_damage > 0:
		context.extra["finalDamage"] = final_damage * get_buff_value()