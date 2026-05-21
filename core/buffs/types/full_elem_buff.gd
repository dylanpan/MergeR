extends BaseBuff

# 全属性适应 — 属性判定时，忽略属性克制关系
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffEnums.BuffTypes.FULL_ELEM
	category = BuffEnums.BuffCategory.STATE_FLAG
	trigger_timing = [BuffEnums.BuffTriggerTiming.ELEMENT_CHECK]
	duration = -1

func on_element_check(context: BuffContext):
	context.extra["ignoreElementAdvantage"] = true