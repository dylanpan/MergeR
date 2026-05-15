extends UIBase
class_name PickScreen

# 角色/发射器选择界面（替代 ClearPickController.js）
# 通过 closed 信号返回结果：close(true) 确认, close(false) 取消

var _select_launchers: Array = []
var _select_order_self_id: int = 0
var _difficulty: int = 5
var _seed: int = 0
var _launchers: Array = []
var _order_selfs: Array = []

func _ready() -> void:
	layer_name = "popup"
	ui_name = "pick_screen"

func on_opened(params = null) -> void:
	var session = ClearRoguelikeManager.game_session
	if session:
		_difficulty = session.get_ui_temp_difficulty()
		_seed = session.get_ui_temp_seed()
	else:
		_difficulty = 5
		_seed = 0
	_select_launchers = []
	_select_order_self_id = 0
	
	_init_data()
	_init_ui()

func on_closed() -> void:
	pass

func _init_data() -> void:
	_launchers = []
	var launcher_dict = MetaConsts.get("launchers", {})
	for key in launcher_dict:
		_launchers.append(launcher_dict[key])
	
	_order_selfs = []
	var order_self_dict = MetaConsts.get("orderSelf", {})
	for key in order_self_dict:
		_order_selfs.append(order_self_dict[key])

func _init_ui() -> void:
	_init_btns()
	_init_launchers()
	_init_order_selfs()

func _init_btns() -> void:
	if not has_node("nodeDialog"):
		return
	var node_dialog = get_node("nodeDialog")
	if node_dialog.has_node("nodeBg") and node_dialog.get_node("nodeBg").has_node("btnBack"):
		var btn = node_dialog.get_node("nodeBg/btnBack")
		if not btn.pressed.is_connected(_on_click_btn_close):
			btn.pressed.connect(_on_click_btn_close)
	if node_dialog.has_node("btnGo"):
		var btn = node_dialog.get_node("btnGo")
		if not btn.pressed.is_connected(_on_click_btn_go):
			btn.pressed.connect(_on_click_btn_go)

func _init_launchers() -> void:
	if not has_node("nodeDialog"):
		return
	if _launchers.is_empty():
		_filter_launchers(0)

func _init_order_selfs() -> void:
	if not has_node("nodeDialog"):
		return
	var node_dialog = get_node("nodeDialog")
	if node_dialog.has_node("listViewOrderSelf"):
		var list_view = node_dialog.get_node("listViewOrderSelf")
		# 清空并填充角色列表
		for child in list_view.get_children():
			list_view.remove_child(child)
		for i in range(_order_selfs.size()):
			var meta = _order_selfs[i]
			# 尝试加载预设的场景组件
			var item_scene_path = "res://ui/components/order_self_item.tscn"
			var item = preload(item_scene_path).instantiate() if ResourceLoader.exists(item_scene_path) else Node.new()
			_render_order_self_item(item, meta, i)
			list_view.add_child(item)

func _render_order_self_item(item, meta: Dictionary, idx: int) -> void:
	if item.has_node("lblName"):
		item.get_node("lblName").text = meta.get("name", "")
	if item.has_node("lblDesc"):
		item.get_node("lblDesc").text = meta.get("desc", "")
	if item.has_node("lblBuff"):
		item.get_node("lblBuff").text = meta.get("buff_desc", "")
	if item.has_node("lblHp"):
		item.get_node("lblHp").text = str(meta.get("hp", 0))
	if item.has_node("lblAtk"):
		item.get_node("lblAtk").text = str(meta.get("atk", 0))
	if item.has_node("lblDef"):
		item.get_node("lblDef").text = str(meta.get("def", 0))
	if item.has_node("lblStep"):
		item.get_node("lblStep").text = str(meta.get("step", 0))
	
	if item.has_node("spSelect"):
		item.get_node("spSelect").visible = (_select_order_self_id == meta.get("id", 0))
	
	item.set_meta("index", idx)
	if item.has_signal("pressed"):
		item.pressed.connect(_on_click_order_self_item.bind(idx))

func _filter_launchers(character_element_type: int) -> void:
	var launcher_dict = MetaConsts.get("launchers", {})
	_launchers = []
	
	for key in launcher_dict:
		var launcher = launcher_dict[key]
		var has_support = false
		var element_types = launcher.get("elementType", [])
		for item in element_types:
			if item.get("type", 0) == 0 or item.get("type", 0) == character_element_type:
				has_support = true
				break
		if has_support:
			_launchers.append(launcher)

func _on_click_order_self_item(idx: int) -> void:
	if idx >= _order_selfs.size():
		return
	var meta = _order_selfs[idx]
	_select_order_self_id = meta.get("id", 0)
	
	# 过滤对应元素属性的发射器
	_filter_launchers(meta.get("elementType", 0))
	_select_launchers = []

func _on_click_btn_close() -> void:
	# 返回 false 表示取消
	close(false)

func _on_click_btn_go() -> void:
	if _select_launchers.size() < 2:
		return
	if _select_order_self_id == 0:
		return
	
	var session = ClearRoguelikeManager.game_session
	if session:
		session.set_select_launchers(_select_launchers)
		session.set_select_order_self_id(_select_order_self_id)
		
		# 生成程序化地图并注入
		var map = MapGenerator.generate_map(_difficulty, _seed)
		session.set_runtime_map(map)
	
	# 返回 true 表示确认
	close(true)