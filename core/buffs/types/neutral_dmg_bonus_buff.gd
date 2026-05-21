extends BaseBuff

# 无属性子弹伤害加成Buff — 提升无属性子弹伤害
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffEnums.BuffTypes.NEUTRAL_DMG_BONUS
	category = BuffEnums.BuffCategory.ATTRIBUTE_MODIFIER
	trigger_timing = [BuffEnums.BuffTriggerTiming.BULLET_CREATE]
	duration = -1

func on_bullet_create(context: BuffContext):
	if context.extra.get("elementType", -1) == 0:
		var bullet_atk = context.extra.get("bulletAtk", 0)
		context.extra["bulletAtk"] = bullet_atk * (1.0 + get_buff_value())