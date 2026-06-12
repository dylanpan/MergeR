extends Control

# ============================================================
# 元素/棋子 UI 组件（替代 ElementUI.js）
# ============================================================

var _entity = null
var _area_id: int = 0
var _col: int = 0
var _row: int = 0
var _drop_complete_handler: Callable = Callable()

func setup(entity, col: int, row: int, area_id: int) -> void:
	_entity = entity
	_col = col
	_row = row
	_area_id = area_id
	_update_display()

func _update_display() -> void:
	if not _entity:
		return
	var data_comp = _entity.get_component(ComponentNames.DATA) as DataComponent
	if data_comp and not data_comp.data.is_empty():
		var hp = data_comp.data.get("hp", 0)
		var atk = data_comp.data.get("atk", 0)
		# 更新 UI 显示（需在场景中绑定 Label 节点）
		if has_node("Label"):
			$Label.text = "ATK:" + str(atk) + " HP:" + str(hp)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		GlobalEventBus.event_ui_update.emit({"type": "order_self"})

func set_drop_complete_handler(handler: Callable) -> void:
	_drop_complete_handler = handler

# 内部调用：在拖拽完成时触发回调
func _on_drop_complete(success: bool) -> void:
	if _drop_complete_handler.is_valid():
		_drop_complete_handler.call(success)
