extends Node

# ============================================================
# 游戏主入口管理器（替代 ClearRoguelikeManager.js）
# Godot Autoload 单例 — 统一编排 UI 流程
# ============================================================

var _world = null
var _game_started: bool = false

func _ready():
	# 延迟启动游戏UI（确保 UIManager 的层级已初始化完成）
	call_deferred("_start_game_ui")

func _start_game_ui():
	if _game_started:
		return
	_game_started = true
	
	# 打开难度选择界面 — 游戏入口
	var ui = UIManager.open_ui("difficulty_select")
	
	if ui == null:
		_game_started = false
		await get_tree().process_frame
		call_deferred("_start_game_ui")
		return
	
	# 监听 closed 信号 — 用户完成选择后触发流程
	ui.closed.connect(_on_difficulty_closed)

func _on_difficulty_closed(confirmed: Variant) -> void:
	if not confirmed:
		# 用户关闭了界面，重新打开
		_game_started = false
		call_deferred("_start_game_ui")
		return
	
	# 打开角色选择界面
	var ui = UIManager.open_ui("pick_screen")
	if ui == null:
		_game_started = false
		call_deferred("_start_game_ui")
		return
	
	# 监听 closed 信号
	ui.closed.connect(_on_pick_closed)

func _on_pick_closed(confirmed: Variant) -> void:
	if not confirmed:
		_game_started = false
		call_deferred("_start_game_ui")
		return
	
	# 打开主游戏界面
	UIManager.open_ui("roguelike_screen")

func create_world(node = null) -> void:
	var world = preload("res://core/world.gd").new()
	world.create(node)
	_world = world

func get_world():
	return _world

func get_systems() -> Array:
	if not _world:
		return []
	return _world.get_systems()

func get_game_state_manager():
	if not _world:
		return null
	return _world.game_state_manager

func get_inventory_manager():
	if not _world:
		return null
	return _world.inventory_manager

func get_entity_service():
	if not _world:
		return null
	return _world.entity_service

func get_ui_root_manager():
	if not _world:
		return null
	return _world.ui_root_manager

# ==================== 新服务层 API ====================

func get_game_state_service():
	if not _world:
		return null
	return _world.game_state_service

func get_inventory_service():
	if not _world:
		return null
	return _world.inventory_service

func get_persistence_service():
	if not _world:
		return null
	return _world.persistence_service

func get_ui_root_service():
	if not _world:
		return null
	return _world.ui_root_service

func get_save_game_data() -> Dictionary:
	var wdm = WorldDataManager
	wdm.prepare_game_data_for_save()
	return wdm.get_cur_game_data()

func get_save_game_json() -> String:
	var data = get_save_game_data()
	var json = JSON.stringify(data)
	if json.is_empty():
		return ""
	return json

func destroy_world() -> void:
	if _world:
		# 先保存当前游戏状态
		var save_json = get_save_game_json()
		if not save_json.is_empty():
			var config = ConfigFile.new()
			config.set_value("save", "clear_roguelike_last", save_json)
			config.save("user://clear_roguelike_save.cfg")
		
		_world.destroy()
		_world = null
	
	# 清理运行时地图
	WorldDataManager.clear_runtime_map()
