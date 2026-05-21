extends BaseBuff

func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffEnums.BuffTypes.NONE
	trigger_timing = []