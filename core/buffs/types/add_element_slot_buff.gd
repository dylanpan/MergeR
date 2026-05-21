extends BaseBuff

# 属性槽位增加Buff — 发射器支持额外属性子弹
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffEnums.BuffTypes.ADD_ELEM_SLOT
	category = BuffEnums.BuffCategory.ATTRIBUTE_MODIFIER
	trigger_timing = [BuffEnums.BuffTriggerTiming.ELEMENT_CHECK]
	duration = -1

func on_element_check(context: BuffContext):
	var additional_slots = context.extra.get("additionalSlots", 0)
	context.extra["additionalSlots"] = additional_slots + get_buff_value()