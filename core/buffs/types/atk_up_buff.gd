extends BaseBuff

# 攻击力加成Buff — 本局战斗攻击力固定加成
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffEnums.BuffTypes.ATK_UP
	category = BuffEnums.BuffCategory.ATTRIBUTE_MODIFIER
	trigger_timing = [BuffEnums.BuffTriggerTiming.ON_APPLY]
	duration = -1

func apply(context: BuffContext):
	super.apply(context)
	if context.entity and context.entity.has_method("get_component"):
		var data_comp = context.entity.get_component(ComponentNames.DATA) as DataComponent
		if data_comp:
			data_comp.data["atk"] = data_comp.data.get("atk", 0) + get_buff_value()

func remove(context: BuffContext):
	if context.entity and context.entity.has_method("get_component"):
		var data_comp = context.entity.get_component(ComponentNames.DATA) as DataComponent
		if data_comp:
			data_comp.data["atk"] = data_comp.data.get("atk", 0) - get_buff_value()
	super.remove(context)