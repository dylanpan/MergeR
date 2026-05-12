extends BaseComponent

# ============================================================
# Buff 组件（替代 BuffComponent.js）
# 存储实体身上的 Buff 列表
# ============================================================

class_name BuffComponent

var buffs: Array = []

func _init():
	comp_name = "Buff"

func add_buff(buff_data: Dictionary) -> void:
	buffs.append(buff_data)

func remove_buff(buff_id: int) -> bool:
	for i in range(buffs.size()):
		if buffs[i].get("id", -1) == buff_id:
			buffs.remove_at(i)
			return true
	return false

func has_buff(buff_type: String) -> bool:
	for buff in buffs:
		if buff.get("type", "") == buff_type:
			return true
	return false

func get_buff_by_type(buff_type: String) -> Dictionary:
	for buff in buffs:
		if buff.get("type", "") == buff_type:
			return buff
	return {}

func clear() -> void:
	buffs.clear()

func to_json() -> Array:
	return buffs.duplicate(true)

func dispose():
	buffs.clear()
	super.dispose()