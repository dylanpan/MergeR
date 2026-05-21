extends BaseBuff

# 全属性兼容Buff — 激活发射器全属性支持模式
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffEnums.BuffTypes.FULL_ELEM_SUPPORT
	category = BuffEnums.BuffCategory.STATE_FLAG
	trigger_timing = [BuffEnums.BuffTriggerTiming.ELEMENT_CHECK]
	duration = -1

func on_element_check(context: BuffContext):
	context.extra["allowAllElements"] = true