extends BaseBuff

# 每回合额外+N步 — 回合开始时增加步数
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffTypes.STEP_PER_ROUND
	category = BuffCategory.ATTRIBUTE_MODIFIER
	trigger_timing = [BuffTriggerTiming.ROUND_START]
	duration = -1

func on_round_start(context: BuffContext):
	var value = get_buff_value()
	var world = GdRoguelikeManager.get_world()
	if world:
		world.game_state_service.add_round_total_step(value)
