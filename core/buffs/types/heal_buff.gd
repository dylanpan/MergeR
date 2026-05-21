extends BaseBuff

# 治愈Buff — 应用时立即恢复生命值，或每回合结束时恢复固定值
var is_instant: bool = true

func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffEnums.BuffTypes.HEAL
	category = BuffEnums.BuffCategory.INSTANT_EFFECT
	trigger_timing = [BuffEnums.BuffTriggerTiming.ON_APPLY, BuffEnums.BuffTriggerTiming.ROUND_END]
	is_instant = buff_data.get("isInstant", true)

func apply(context: BuffContext):
	super.apply(context)
	if is_instant:
		_heal_target(context.entity)
		is_expired = true

func on_round_end(context: BuffContext):
	super.on_round_end(context)
	if not is_instant:
		_heal_target(context.entity)

func _heal_target(target) -> void:
	if not target:
		return
	if target.has_method("get_component"):
		var data_comp = target.get_component(ComponentNames.DATA) as DataComponent
		if data_comp and data_comp.data:
			var heal_amount = get_buff_value()
			var max_hp = data_comp.data.get("maxHp", data_comp.data.get("hp", 0) + heal_amount)
			data_comp.data["hp"] = min(data_comp.data.get("hp", 0) + heal_amount, max_hp)