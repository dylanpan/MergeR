extends BaseBuff

# 防御力加成Buff — 本局战斗防御力固定加成
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffTypes.DEF_UP
	category = BuffCategory.ATTRIBUTE_MODIFIER
	trigger_timing = [BuffTriggerTiming.ON_APPLY]
	duration = -1

func apply(context: BuffContext):
	super.apply(context)
	if context.entity and context.entity.has_method("get_component"):
		var data_comp = context.entity.get_component("Data") as DataComponent
		if data_comp:
			data_comp.data["def"] = data_comp.data.get("def", 0) + get_buff_value()

func remove(context: BuffContext):
	if context.entity and context.entity.has_method("get_component"):
		var data_comp = context.entity.get_component("Data") as DataComponent
		if data_comp:
			data_comp.data["def"] = data_comp.data.get("def", 0) - get_buff_value()
	super.remove(context)