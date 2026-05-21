extends BaseBuff

# 全属性提升Buff — 所有基础属性按比例提升
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffEnums.BuffTypes.ALL_STATS
	category = BuffEnums.BuffCategory.ATTRIBUTE_MODIFIER
	trigger_timing = [BuffEnums.BuffTriggerTiming.ON_APPLY, BuffEnums.BuffTriggerTiming.ON_REMOVE]
	duration = -1

func apply(context: BuffContext):
	super.apply(context)
	if context.entity and context.entity.has_method("get_component"):
		var data_comp = context.entity.get_component(ComponentNames.DATA) as DataComponent
		if data_comp:
			var multiplier = get_buff_value()
			data_comp.data["atk"] = floor(data_comp.data.get("atk", 0) * multiplier)
			data_comp.data["def"] = floor(data_comp.data.get("def", 0) * multiplier)
			data_comp.data["hp"] = floor(data_comp.data.get("hp", 0) * multiplier)
			data_comp.data["maxHp"] = floor(data_comp.data.get("maxHp", data_comp.data.get("hp", 0)) * multiplier)

func remove(context: BuffContext):
	if context.entity and context.entity.has_method("get_component"):
		var data_comp = context.entity.get_component(ComponentNames.DATA) as DataComponent
		if data_comp:
			var multiplier = 1.0 / get_buff_value()
			data_comp.data["atk"] = floor(data_comp.data.get("atk", 0) * multiplier)
			data_comp.data["def"] = floor(data_comp.data.get("def", 0) * multiplier)
			data_comp.data["hp"] = floor(data_comp.data.get("hp", 0) * multiplier)
			data_comp.data["maxHp"] = floor(data_comp.data.get("maxHp", data_comp.data.get("hp", 0)) * multiplier)
	super.remove(context)