extends BaseComponent

# ============================================================
# 拖拽组件（替代 DragComponent.js）
# 处理棋子的拖拽交互逻辑
# ============================================================

class_name DragComponent

var is_dragging: bool = false
var drag_source: int = -1  # area_id
var drag_source_index: int = -1
var drag_target: int = -1
var is_valid_target: bool = false
var drag_offset: Vector2 = Vector2.ZERO

func _init():
	comp_name = "Drag"

func start_drag(source_area: int, source_index: int) -> void:
	is_dragging = true
	drag_source = source_area
	drag_source_index = source_index

func end_drag() -> void:
	is_dragging = false
	drag_source = -1
	drag_source_index = -1
	drag_target = -1
	is_valid_target = false

func set_target(area_id: int) -> void:
	drag_target = area_id

func validate_target(can_drop: bool) -> void:
	is_valid_target = can_drop