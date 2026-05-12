extends BaseBuff

# 子弹数量Buff — 每回合额外发射子弹
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffTypes.BULLET_COUNT
	category = BuffCategory.ATTRIBUTE_MODIFIER
	trigger_timing = [BuffTriggerTiming.BULLET_CREATE]
	duration = -1

func on_bullet_create(context: BuffContext):
	var bullet_count = context.extra.get("bulletCount", 1)
	context.extra["bulletCount"] = bullet_count + get_buff_value()