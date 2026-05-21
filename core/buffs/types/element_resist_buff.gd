extends BaseBuff

# 元素抗性Buff — 减免所有元素伤害
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffEnums.BuffTypes.ELEM_RESIST
	category = BuffEnums.BuffCategory.ATTRIBUTE_MODIFIER
	trigger_timing = [BuffEnums.BuffTriggerTiming.HURT]
	duration = -1

func on_hurt(context: BuffContext):
	var element_type = context.extra.get("elementType", 0)
	if element_type > 0:
		var damage = context.extra.get("damage", 0)
		context.extra["damage"] = damage * (1.0 - get_buff_value())