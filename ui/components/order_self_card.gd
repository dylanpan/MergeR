extends Control

# ============================================================
# 己方单位卡片 UI（替代 OrderSelfUI.js）
# ============================================================

var _entity = null

func setup(entity) -> void:
	_entity = entity
	_update_display()

func _update_display() -> void:
	if not _entity:
		return
	var data_comp = _entity.get_component("Data") as DataComponent
	if data_comp and not data_comp.data.is_empty():
		var hp = data_comp.data.get("hp", 0)
		var atk = data_comp.data.get("atk", 0)
		var step = data_comp.data.get("step", 0)
		if has_node("HpLabel"):
			$HpLabel.text = "HP: " + str(hp)
		if has_node("AtkLabel"):
			$AtkLabel.text = "ATK: " + str(atk)
		if has_node("StepLabel"):
			$StepLabel.text = "Step: " + str(step)