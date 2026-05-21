extends BaseBuff

func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffEnums.BuffTypes.RANDOM_ELEM
	trigger_timing = [BuffEnums.BuffTriggerTiming.ON_APPLY]

func apply(context: BuffContext):
	super.apply(context)
	if context.entity and context.entity.has_method("get_component"):
		var elem_change = context.entity.get_component(ComponentNames.ELEMENT_CHANGE) as ElementChangeComponent
		if elem_change:
			var rnd_type = randi() % 4 + 1
			elem_change.change_to(rnd_type, 2)
