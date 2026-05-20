extends UIBase
class_name RoguelikeScreen

# 主游戏界面（替代 ClearRoguelikeController.js）
# 管理游戏主循环、步数更新、节点切换

var _runtime_map = null
var _current_node_id = null
var _completed_node_ids: Dictionary = {}
var _map_preview: UIBase = null

func _ready() -> void:
	layer_name = "hud"
	ui_name = "roguelike_screen"

func on_opened(params = null) -> void:
	_init_data(params)
	_init_ui()

func on_closed() -> void:
	# 断开事件连接
	if GlobalEventBus.event_update_by_step.is_connected(_on_update_step):
		GlobalEventBus.event_update_by_step.disconnect(_on_update_step)
	if GlobalEventBus.event_update_game_over.is_connected(_on_game_over):
		GlobalEventBus.event_update_game_over.disconnect(_on_game_over)
	if GlobalEventBus.event_update_game_win.is_connected(_on_game_win):
		GlobalEventBus.event_update_game_win.disconnect(_on_game_win)
	if GlobalEventBus.event_game_state.is_connected(_on_game_state_update):
		GlobalEventBus.event_game_state.disconnect(_on_game_state_update)
	
	GdRoguelikeManager.destroy_world()

func _init_data(param: Dictionary = {}) -> void:
	var session = GdRoguelikeManager.game_session
	if not session:
		return
	
	if param and param.has("difficulty"):
		session.set_ui_temp_data(param.difficulty, param.get("seed", randi() % 0x7FFFFFFF))
	
	if not session.has_runtime_map():
		var difficulty = session.get_ui_temp_difficulty()
		var seed = session.get_ui_temp_seed()
		if difficulty > 0 and seed > 0:
			var map = MapGenerator.generate_map(difficulty, seed)
			session.set_runtime_map(map)

func _init_event() -> void:
	GlobalEventBus.event_update_by_step.connect(_on_update_step)
	# 旧信号（向后兼容）
	GlobalEventBus.event_update_game_over.connect(_on_game_over)
	GlobalEventBus.event_update_game_win.connect(_on_game_win)
	# 新通用信号
	GlobalEventBus.event_game_state.connect(_on_game_state_update)

func _init_ui() -> void:
	_init_event()
	_init_btns()
	_start_game()

func _init_btns() -> void:
	if not has_node("nodeDialog"):
		return
	var node_dialog = get_node("nodeDialog")
	if node_dialog.has_node("btnBack"):
		var btn_back = node_dialog.get_node("btnBack")
		if not btn_back.pressed.is_connected(_on_click_btn_back):
			btn_back.pressed.connect(_on_click_btn_back)
	if node_dialog.has_node("btnMap"):
		var btn_map = node_dialog.get_node("btnMap")
		if not btn_map.pressed.is_connected(_on_click_btn_map):
			btn_map.pressed.connect(_on_click_btn_map)

func _start_game() -> void:
	_runtime_map = GdRoguelikeManager.game_session.get_runtime_map() if GdRoguelikeManager.game_session else null
	_current_node_id = null
	_completed_node_ids = {}
	
	_map_preview = UIManager.open_ui("map_preview", {
		"current_node_id": _current_node_id,
		"completed_node_ids": _completed_node_ids
	})
	
	if _runtime_map and _runtime_map.layers.size() > 0:
		var first_node = _runtime_map.layers[0]
		if first_node:
			_current_node_id = first_node.get("id", null)
			var ui_container = get_node("nodeDialog") if has_node("nodeDialog") else self
			GdRoguelikeManager.create_world(ui_container)
			_on_update_step()

func _on_update_step() -> void:
	var world = GdRoguelikeManager.get_world()
	if world and world.has_method("tick"):
		world.tick(0.0)
	else:
		var systems = GdRoguelikeManager.get_systems()
		for system in systems:
			system.update(0.0)

func _on_game_state_update(data: Dictionary) -> void:
	var type = data.get("type", "")
	match type:
		"over":
			_on_game_over()
		"win":
			_on_game_win()

func _on_game_over() -> void:
	GdRoguelikeManager.destroy_world()
	_close_to_pick()

func _on_game_win() -> void:
	GdRoguelikeManager.destroy_world()
	
	if _current_node_id:
		_completed_node_ids[_current_node_id] = true
	
	if _runtime_map and _runtime_map.has("gameLevels"):
		var current_level_data = _runtime_map.game_levels.get(_current_node_id, {})
		var next_nodes = current_level_data.get("next", [])
		if next_nodes.size() > 0:
			var next_node_id = next_nodes[0]
			var next_node = null
			for node in _runtime_map.layers:
				if node.get("id", 0) == next_node_id:
					next_node = node
					break
			if next_node:
				_current_node_id = next_node.get("id", null)
				var ui_container = get_node("nodeDialog") if has_node("nodeDialog") else self
				GdRoguelikeManager.create_world(ui_container)
				_on_update_step()
				return
	
	_close_to_pick()

func _close_to_pick() -> void:
	UIManager.open_ui("difficulty_select")
	close()

func _on_click_btn_back() -> void:
	GdRoguelikeManager.destroy_world()
	close()

func _on_click_btn_map() -> void:
	UIManager.open_ui("map_preview", {
		"current_node_id": _current_node_id,
		"completed_node_ids": _completed_node_ids
	})