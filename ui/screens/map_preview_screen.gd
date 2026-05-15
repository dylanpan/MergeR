extends UIBase
class_name MapPreviewScreen

# 地图预览界面（替代 ClearMapPreviewController.js）

var _runtime_map = null
var _node_components: Dictionary = {}
var _current_node_id = null
var _completed_node_ids: Dictionary = {}

func _ready() -> void:
	layer_name = "popup"
	ui_name = "map_preview"

func on_opened(params = null) -> void:
	var session = ClearRoguelikeManager.game_session
	if not session or not session.has_runtime_map():
		push_warning("MapPreviewScreen: 没有运行时地图数据")
		return
	
	_runtime_map = session.get_runtime_map()
	_current_node_id = params.get("current_node_id", null) if params else null
	_completed_node_ids = params.get("completed_node_ids", {}) if params else {}
	
	_init_ui()
	_render_map()

func on_closed() -> void:
	_node_components.clear()
	_runtime_map = null

func open(param: Dictionary = {}) -> void:
	var session = ClearRoguelikeManager.game_session
	if not session or not session.has_runtime_map():
		return
	
	_runtime_map = session.get_runtime_map()
	_current_node_id = param.get("current_node_id", null)
	_completed_node_ids = param.get("completed_node_ids", {})
	
	_init_ui()
	_render_map()
	visible = true

func close() -> void:
	_node_components.clear()
	_runtime_map = null
	visible = false

func _init_ui() -> void:
	if not has_node("nodeDialog"):
		return
	var node_dialog = get_node("nodeDialog")
	
	if node_dialog.has_node("nodeBg") and node_dialog.get_node("nodeBg").has_node("btnBack"):
		var btn = node_dialog.get_node("nodeBg/btnBack")
		if not btn.pressed.is_connected(_on_btn_back):
			btn.pressed.connect(_on_btn_back)
	
	if _runtime_map and node_dialog.has_node("nodeTotalInfo"):
		var total_info = node_dialog.get_node("nodeTotalInfo")
		if total_info.has_node("lblDifficulty"):
			total_info.get_node("lblDifficulty").text = "难度 " + str(_runtime_map.difficulty)
		if total_info.has_node("lblSeed"):
			total_info.get_node("lblSeed").text = "种子: " + str(_runtime_map.seed)
		if total_info.has_node("lblTotalNodes"):
			total_info.get_node("lblTotalNodes").text = "共 " + str(_runtime_map.layers.size()) + " 个关卡"

func _on_btn_back() -> void:
	if is_inside_tree():
		var parent_layer = get_parent()
		if parent_layer is CanvasLayer:
			close()
			return
	close()

func _render_map() -> void:
	if not _runtime_map or not has_node("nodeDialog"):
		return
	var node_dialog = get_node("nodeDialog")
	if not node_dialog.has_node("nodeMapContainer"):
		return
	var map_container = node_dialog.get_node("nodeMapContainer")
	
	for child in map_container.get_children():
		map_container.remove_child(child)
		child.queue_free()
	
	var layer_groups: Dictionary = {}
	for node_data in _runtime_map.layers:
		var level = node_data.get("level", 0)
		if not layer_groups.has(level):
			layer_groups[level] = []
		layer_groups[level].append(node_data)
	
	var total_layers = layer_groups.size()
	var container_height = map_container.size.y if map_container.size.y > 0 else 600
	var layer_height = container_height / (total_layers + 1.0) if total_layers > 0 else 100
	
	_draw_connections(layer_groups, layer_height, map_container)
	
	var levels = layer_groups.keys()
	levels.sort()
	for level in levels:
		var nodes = layer_groups[level]
		var y_pos = container_height - layer_height * level
		var spacing = map_container.size.x / (nodes.size() + 1.0)
		
		for index in range(nodes.size()):
			var node_data = nodes[index]
			var x_pos = spacing * (index + 1)
			_create_map_node(node_data, x_pos, y_pos, map_container)

func _draw_connections(layer_groups: Dictionary, layer_height: float, map_container: Control) -> void:
	var levels = layer_groups.keys()
	levels.sort()
	
	for level in levels:
		var nodes = layer_groups[level]
		if level == 0:
			continue
		
		var prev_nodes = layer_groups.get(level - 1, [])
		for node_data in nodes:
			var prev_ids = node_data.get("prev", [])
			var node_idx = nodes.find(node_data)
			var spacing = map_container.size.x / (nodes.size() + 1.0)
			var x_pos = spacing * (node_idx + 1)
			var y_pos = map_container.size.y - layer_height * level
			
			for prev_id in prev_ids:
				for prev_node in prev_nodes:
					if prev_node.get("id", 0) == prev_id:
						var prev_idx = prev_nodes.find(prev_node)
						var prev_spacing = map_container.size.x / (prev_nodes.size() + 1.0)
						var prev_x = prev_spacing * (prev_idx + 1)
						var prev_y = map_container.size.y - layer_height * (level - 1)
						
						var line = Line2D.new()
						line.add_point(Vector2(prev_x + 30, prev_y + 30))
						line.add_point(Vector2(x_pos + 30, y_pos + 30))
						line.width = 2.0
						line.default_color = Color(0.6, 0.6, 0.6, 0.5)
						line.set_as_top_level(true)
						map_container.add_child(line)
						break

func _create_map_node(node_data: Dictionary, x: float, y: float, map_container: Control) -> void:
	var map_node = Node.new()
	map_node.set_name("MapNode_" + str(node_data.get("id", 0)))
	
	var btn = Button.new()
	btn.position = Vector2(x, y)
	btn.size = Vector2(60, 60)
	btn.text = str(node_data.get("level", 0))
	map_node.add_child(btn)
	
	var is_current = node_data.get("id", 0) == _current_node_id
	var completed = _completed_node_ids.has(node_data.get("id", 0))
	
	if is_current:
		btn.modulate = Color(1, 1, 0)
	elif completed:
		btn.modulate = Color(0.5, 0.5, 0.5)
	
	map_container.add_child(map_node)
	_node_components[str(node_data.get("id", 0))] = map_node

func _get_node_url(node_type: int) -> String:
	match node_type:
		1: return "battle"
		2: return "elite"
		3: return "boss"
		4: return "shop"
		5: return "event"
		6: return "rest"
		7: return "treasure"
		_: return "battle"

func _is_node_accessible(node_id) -> bool:
	if _current_node_id == null:
		return true
	var current_level_data = _runtime_map.game_levels.get(_current_node_id, {})
	var next_nodes = current_level_data.get("next", [])
	return next_nodes.has(node_id)