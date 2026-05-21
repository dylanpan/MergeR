extends BaseBuff

# 连击概率+15% — 子弹创建时，有概率额外增加1颗子弹
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffEnums.BuffTypes.COMBO_RATE
	category = BuffEnums.BuffCategory.ATTRIBUTE_MODIFIER
	trigger_timing = [BuffEnums.BuffTriggerTiming.BULLET_CREATE]
	duration = -1

func on_bullet_create(context: BuffContext):
	var roll = randf()
	if roll < get_buff_value():
		var bullet_count = context.extra.get("bulletCount", 1)
		context.extra["bulletCount"] = bullet_count + 1