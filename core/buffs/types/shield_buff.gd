extends BaseBuff

# 护盾Buff — 受击时优先扣除护盾值
var shield_value: float = 0.0

func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffTypes.SHIELD
	category = BuffCategory.VALUE_CACHE
	trigger_timing = [BuffTriggerTiming.HURT]
	shield_value = buff_data.get("value", 0.0)

func apply(context: BuffContext):
	super.apply(context)
	# 如果通过 apply 触发，同时通过 ShieldComponent 添加护盾
	if context.entity and context.entity.has_method("get_component"):
		var shield_comp = context.entity.get_component(ComponentNames.SHIELD) as ShieldComponent
		if shield_comp:
			shield_comp.add_shield(value)

func on_hurt(context: BuffContext):
	if shield_value <= 0:
		return
	var incoming_damage = context.extra.get("modifiedValue", 0)
	if incoming_damage <= 0:
		return
	
	if shield_value >= incoming_damage:
		shield_value -= incoming_damage
		context.extra["modifiedValue"] = 0
	else:
		var remaining_damage = incoming_damage - shield_value
		shield_value = 0
		context.extra["modifiedValue"] = remaining_damage
		is_expired = true

func get_buff_value() -> float:
	return shield_value

func to_json() -> Dictionary:
	var result = super.to_json()
	result["shieldValue"] = shield_value
	return result