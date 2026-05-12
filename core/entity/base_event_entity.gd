extends BaseEntity

# ============================================================
# 事件实体基类（替代 BaseEventEntity.js）
# ============================================================

class_name BaseEventEntity

var event_id: int = 0
var event_type: String = ""

func _init(p_event_id: int = 0, p_type: String = ""):
	event_id = p_event_id
	event_type = p_type
	
	var data_comp = DataComponent.new({"id": p_event_id, "type": p_type})
	add_component(data_comp)

func on_enter() -> Dictionary:
	# 进入事件时调用，返回事件数据给 UI
	return {"id": event_id, "type": event_type}

func on_option_select(option_id: int) -> void:
	# 子类重写
	pass