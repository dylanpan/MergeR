extends BaseBuff

# 土属性子弹穿透+1 — 子弹创建时，穿透次数 += value
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffEnums.BuffTypes.ELEM_BULLET_PIERCE
	category = BuffEnums.BuffCategory.ATTRIBUTE_MODIFIER
	trigger_timing = [BuffEnums.BuffTriggerTiming.BULLET_CREATE]
	duration = -1

func on_bullet_create(context: BuffContext):
	var pierce = context.extra.get("pierceCount", 0)
	context.extra["pierceCount"] = pierce + get_buff_value()