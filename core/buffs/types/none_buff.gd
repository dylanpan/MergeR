extends BaseBuff

func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffTypes.NONE
	trigger_timing = []