extends BaseBuff

# 复活Buff — 死亡时自动复活并恢复生命值
func _init(buff_data: Dictionary = {}):
	super(buff_data)
	type = BuffTypes.REVIVE
	category = BuffCategory.TRIGGER_EFFECT
	trigger_timing = [BuffTriggerTiming.HURT]
	duration = -1

func on_hurt(context: BuffContext):
	if not context.entity:
		return
	if context.entity.has_method("get_component"):
		var data_comp = context.entity.get_component(ComponentNames.DATA) as DataComponent
		if data_comp and data_comp.data:
			var hp = data_comp.data.get("hp", 0)
			var max_hp = data_comp.data.get("maxHp", hp)
			if hp <= 0:
				# 复活并恢复指定百分比生命
				var heal_amount = floor(max_hp * (get_buff_value() / 100.0))
				data_comp.data["hp"] = heal_amount
				context.extra["isDead"] = false
				# 复活效果消耗后移除
				is_expired = true