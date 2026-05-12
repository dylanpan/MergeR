extends BaseBuff

# 双倍行动Buff — 行动阶段额外增加一次行动机会
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffTypes.DOUBLE_ACT
	category = BuffCategory.TRIGGER_EFFECT
	trigger_timing = [BuffTriggerTiming.ACTION_PHASE]
	duration = -1

func on_action_phase(context: BuffContext):
	# 标记允许额外行动
	context.extra["doubleAction"] = true
	# 双倍行动触发后消耗
	is_expired = true