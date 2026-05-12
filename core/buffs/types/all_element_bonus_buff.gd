extends BaseBuff

# 全属性子弹伤害加成Buff — 提升所有属性子弹伤害
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffTypes.ALL_ELEM_BONUS
	category = BuffCategory.ATTRIBUTE_MODIFIER
	trigger_timing = [BuffTriggerTiming.BULLET_CREATE]
	duration = -1

func on_bullet_create(context: BuffContext):
	var element_type = context.extra.get("elementType", -1)
	if element_type >= 0:
		var bullet_atk = context.extra.get("bulletAtk", 0)
		context.extra["bulletAtk"] = bullet_atk * (1.0 + get_buff_value())