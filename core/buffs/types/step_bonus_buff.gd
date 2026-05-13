extends BaseBuff

# 即时步数奖励Buff — 使用时立即获得额外步数
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffTypes.STEP_BONUS
	category = BuffCategory.INSTANT_EFFECT
	trigger_timing = [BuffTriggerTiming.ON_APPLY]
	duration = 0

func apply(context: BuffContext):
	super.apply(context)
	if context.entity and context.entity.has_method("get_component"):
		var data_comp = context.entity.get_component(ComponentNames.DATA) as DataComponent
		if data_comp:
			var step = data_comp.data.get("step", 0)
			data_comp.data["step"] = step + get_buff_value()
	# 即时效果用完即失效
	is_expired = true