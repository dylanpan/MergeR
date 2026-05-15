class_name GameSessionService

# ============================================================
# 游戏会话服务
# 管理 UI 面板间的跨屏幕数据传输（难度选择 → 角色选择 → 主游戏）
# 替代 WorldDataManager 的 UI 临时数据 + 选择数据 + 运行时地图职责
# ============================================================

# 初始化标志（用于检测游戏是否已开始）
var init_flag: bool = false

# UI 流程参数
var temp_ui_difficulty: int = 5
var temp_ui_seed: int = 0

# 选择数据
var select_launchers: Array = []
var select_order_self_id: int = 0

# 运行时地图
var runtime_map = null

func _init():
	pass

# ==================== Init Flag ====================

func set_init_flag(value: bool) -> void:
	init_flag = value

func get_init_flag() -> bool:
	return init_flag

# ==================== UI 临时数据 ====================

func set_ui_temp_data(difficulty: int, seed: int) -> void:
	temp_ui_difficulty = difficulty
	temp_ui_seed = seed

func get_ui_temp_difficulty() -> int:
	return temp_ui_difficulty

func get_ui_temp_seed() -> int:
	return temp_ui_seed

# ==================== 选择数据 ====================

func set_select_launchers(value: Array) -> void:
	select_launchers = value

func get_select_launchers() -> Array:
	return select_launchers

func set_select_order_self_id(value: int) -> void:
	select_order_self_id = value

func get_selected_character_template_id() -> int:
	return select_order_self_id

func get_selected_character_template() -> Dictionary:
	if not select_order_self_id:
		return {}
	return MetaConsts.get("orderSelf", {}).get(select_order_self_id, {})

# ==================== 运行时地图 ====================

func set_runtime_map(map_model) -> void:
	runtime_map = map_model

func clear_runtime_map() -> void:
	runtime_map = null

func has_runtime_map() -> bool:
	return runtime_map != null

func get_runtime_map():
	return runtime_map

# ==================== 重置 ====================

func reset() -> void:
	init_flag = false
	temp_ui_difficulty = 5
	temp_ui_seed = 0
	select_launchers.clear()
	select_order_self_id = 0
	runtime_map = null