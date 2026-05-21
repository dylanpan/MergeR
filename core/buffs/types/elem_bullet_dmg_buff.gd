extends BaseBuff

# 属性子弹伤害+5% — 子弹创建时，子弹伤害 *= (1 + value)
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffEnums.BuffTypes.ELEM_BULLET_DMG
	category = BuffEnums.BuffCategory.ATTRIBUTE_MODIFIER
	trigger_timing = [BuffEnums.BuffTriggerTiming.BULLET_CREATE]
	duration = -1

func on_bullet_create(context: BuffContext):
	var bullet_atk = context.extra.get("bulletAtk", 0)
	context.extra["bulletAtk"] = bullet_atk * (1.0 + get_buff_value())