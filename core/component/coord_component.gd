extends BaseComponent

# ============================================================
# 坐标组件（替代 CoordComponent.js）
# 存储实体在棋盘上的位置
# ============================================================

class_name CoordComponent

var col: int = 0
var row: int = 0
var area_id: int = 0

func _init(p_col: int = 0, p_row: int = 0, p_area_id: int = 0):
	comp_name = "Coord"
	col = p_col
	row = p_row
	area_id = p_area_id

func set_position(p_col: int, p_row: int) -> void:
	col = p_col
	row = p_row