extends BaseComponent

# ============================================================
# 发射器组件（替代 LauncherComponent.js）
# ============================================================

class_name LauncherComponent

var launcher_id: int = 0
var element_type: int = 0
var range: int = 3
var atk_bonus: int = 0

func _init(p_launcher_id: int = 0, p_element_type: int = 0, p_range: int = 3, p_atk: int = 0):
	comp_name = "Launcher"
	launcher_id = p_launcher_id
	element_type = p_element_type
	range = p_range
	atk_bonus = p_atk