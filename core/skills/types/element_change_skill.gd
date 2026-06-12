extends BaseSkill

# 元素变化技能 — 切换实体攻击元素类型
func _init(p_skill_data: Dictionary = {}):
	super(p_skill_data)
	_register_event_listener()

func _register_event_listener() -> void:
	GlobalEventBus.event_battle_update.connect(_on_battle_update)

func _on_battle_update(data: Dictionary) -> void:
	if data.get("type", "") != "self_atk":
		return
	execute(data)

func on_execute(context: Dictionary) -> void:
	var element_type = context.get("elementType", skill_data.get("element", randi() % 4 + 1))
	var duration = context.get("duration", 3)
	var entity_id = context.get("entityId", "")
	
	# 获取实体
	var target = WorldHelper.get_entity_by_id(entity_id)
	if not target:
		return
	
	var elem_change = target.get_component(ComponentNames.ELEMENT_CHANGE) as ElementChangeComponent
	if elem_change:
		elem_change.change_to(element_type, duration)
	
	# 元素变化事件通知 → UI更新元素显示
	GlobalEventBus.event_battle_update.emit({
		"type": "element_change",
		"entity_id": entity_id,
		"element_type": element_type
	})

# 技能注册
SkillRegistry.register_skill("element_change", ElementChangeSkill)
