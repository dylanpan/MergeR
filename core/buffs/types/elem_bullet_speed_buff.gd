extends BaseBuff

# 风属性子弹速度+10% — 子弹创建时，移动速度 *= (1 + value)
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffTypes.ELEM_BULLET_SPEED
	category = BuffCategory.ATTRIBUTE_MODIFIER
	trigger_timing = [BuffTriggerTiming.BULLET_CREATE]
	duration = -1

func on_bullet_create(context: BuffContext):
	var bullet_speed = context.extra.get("bulletSpeed", 1.0)
	context.extra["bulletSpeed"] = bullet_speed * (1.0 + get_buff_value())