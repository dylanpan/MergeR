extends BaseBuff

# 范围伤害 — 伤害结算时，对目标周围格子产生溅射伤害
var radius: int = 1

func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffEnums.BuffTypes.AREA_DMG
	category = BuffEnums.BuffCategory.STATE_FLAG
	trigger_timing = [BuffEnums.BuffTriggerTiming.DAMAGE_SETTLE]
	radius = buff_data.get("radius", 1)
	duration = -1

func on_damage_settle(context: BuffContext):
	context.extra["areaDamage"] = {
		"enabled": true,
		"radius": radius,
		"damageRatio": get_buff_value()
	}