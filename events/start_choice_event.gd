extends BaseEventEntity

class_name StartChoiceEvent

var _selected_choice: Dictionary = {}

func _init(p_event_id: int = 70004):
	super(p_event_id, "start_choice")

func get_ui_data() -> Dictionary:
	var data = _meta.duplicate()
	data["options"] = []
	var choices = _meta.get("choices", [])
	for i in range(choices.size()):
		var c = choices[i]
		data["options"].append({"id": i + 1, "text": c.get("text", "选择"), "icon": c.get("icon", "")})
	return data

func on_option_select(option_id: int) -> void:
	var choices = _meta.get("choices", [])
	if option_id < 1 or option_id > choices.size():
		return
	
	var chosen = choices[option_id - 1]
	_apply_choice(chosen)

func _apply_choice(choice: Dictionary) -> void:
	var buff_id = choice.get("buffId", 90001)
	
	var world = GdRoguelikeManager.get_world()
	if not world:
		return
	
	var self_entities = world.entity_service.get_order_self()
	for entity in self_entities:
		BuffSystem.get_instance().add_buff(entity, buff_id, 0, -1, "event_start_choice")

func on_enter() -> Dictionary:
	return get_ui_data()