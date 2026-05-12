extends BaseBuff

# 防御倍率Buff — 受到的所有伤害按比例降低
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffTypes.DEF_MULTI
	category = BuffCategory.ATTRIBUTE_MODIFIER
	trigger_timing = [BuffTriggerTiming.HURT]
	duration = -1

func on_hurt(context: BuffContext):
	var damage = context.extra.get("damage", 0)
	if damage > 0:
		var reduce_rate = get_buff_value() - 1
		context.extra["damage"] = damage * (1.0 - reduce_rate)