extends ElementUI
class_name ShotElementUI

# 射击元素UI（替代 ShotElementUI.js）
# 继承自ElementUI，管理射击按钮状态

func setup(p_entity, p_area_id: int = 0) -> void:
	super(p_entity, p_area_id)

func init() -> void:
	update_ui_icon()
	update_finish_button_state()

func update_ui_icon() -> void:
	add_icon("res://assets/icons/2120701.png")

func update_finish_button_state() -> void:
	# 检查是否有子弹
	var world = ClearRoguelikeManager.get_world()
	var has_bullets = false
	
	if world:
		for entity_item in world.entity_service.get_bullets():
			var data_comp = entity_item.get_component(ComponentNames.DATA) if entity_item.has_method("get_component") else null
			if data_comp and data_comp.data:
				if data_comp.data.get("type", 0) == 1:
					has_bullets = true
					break
	
	if has_node("spFinish"):
		get_node("spFinish").visible = has_bullets
	if has_node("spEmpty"):
		get_node("spEmpty").visible = not has_bullets

func _on_drag_complete(from_entity_ui, to_entity) -> void:
	# 不处理拖拽逻辑
	return