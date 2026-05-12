extends BaseBuff

# 元素属性伤害+15% — 伤害计算阶段，最终伤害 *= (1 + value)
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffTypes.ELEM_DMG
	category = BuffCategory.ATTRIBUTE_MODIFIER
	trigger_timing = [BuffTriggerTiming.DAMAGE_CALCULATE]
	duration = -1

func on_damage_calculate(context: BuffContext):
	var final_damage = context.extra.get("finalDamage", 0)
	if final_damage > 0:
		context.extra["finalDamage"] = final_damage * (1.0 + get_buff_value())