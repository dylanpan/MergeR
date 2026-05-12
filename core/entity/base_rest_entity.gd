extends BaseEntity

# ============================================================
# 休息点实体基类（替代 BaseRestEntity.js）
# ============================================================

class_name BaseRestEntity

var rest_id: int = 0
var rest_type: String = ""

func _init(p_rest_id: int = 0, p_type: String = ""):
	rest_id = p_rest_id
	rest_type = p_type
	
	var data_comp = DataComponent.new({"id": p_rest_id, "type": p_type})
	add_component(data_comp)

func on_enter() -> Dictionary:
	return {"id": rest_id, "type": rest_type}

func on_confirm() -> void:
	# 子类重写
	pass

func on_skip() -> void:
	# 子类重写
	pass