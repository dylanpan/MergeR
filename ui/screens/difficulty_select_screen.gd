extends UIBase
class_name DifficultySelectScreen

# 难度选择界面（替代 ClearDifficultySelectController.js）
# 通过 closed 信号返回结果：close(true) 确认, close(false) 取消

var _selected_difficulty: int = 5
var _seed: int = 0
var _difficulty_names: Array = ["简单", "入门", "普通", "进阶", "挑战", "困难", "专家", "大师", "噩梦", "地狱"]

func _ready() -> void:
	layer_name = "popup"
	ui_name = "difficulty_select"

func on_opened(params = null) -> void:
	_selected_difficulty = params.get("difficulty", 5) if params else 5
	_seed = randi() % 0x7FFFFFFF
	call_deferred("_init_ui")

func on_closed() -> void:
	pass

func _init_ui() -> void:
	_init_btns()
	_init_slider()
	_update_difficulty_info()

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
	if node_dialog.has_node("btnRandomSeed"):
		var btn = node_dialog.get_node("btnRandomSeed")
		if not btn.pressed.is_connected(_on_click_random_seed):
			btn.pressed.connect(_on_click_random_seed)

func _init_slider() -> void:
	if not has_node("nodeDialog"):
		return
	var node_dialog = get_node("nodeDialog")
	if node_dialog.has_node("sliderDifficulty"):
		var slider = node_dialog.get_node("sliderDifficulty")
		slider.min_value = 1
		slider.max_value = 10
		slider.value = _selected_difficulty
		if not slider.value_changed.is_connected(_on_slider_changed):
			slider.value_changed.connect(_on_slider_changed)
	if node_dialog.has_node("inputSeed"):
		var input_seed = node_dialog.get_node("inputSeed") as LineEdit
		if input_seed:
			input_seed.text = str(_seed)

func _on_slider_changed(value: float) -> void:
	_selected_difficulty = floori(value)
	_update_difficulty_info()

func _on_click_random_seed() -> void:
	_seed = randi() % 0x7FFFFFFF
	if has_node("nodeDialog/inputSeed"):
		var node = get_node("nodeDialog/inputSeed") as LineEdit
		if node:
			node.text = str(_seed)

func _update_difficulty_info() -> void:
	if not has_node("nodeDialog"):
		return
	var node_dialog = get_node("nodeDialog")
	var diff = _selected_difficulty
	
	if node_dialog.has_node("lblDifficultyLevel"):
		node_dialog.get_node("lblDifficultyLevel").text = "难度 " + str(diff)
	if node_dialog.has_node("lblDifficultyName"):
		node_dialog.get_node("lblDifficultyName").text = _difficulty_names[diff - 1]
	if node_dialog.has_node("lblInfo"):
		var rounds = diff * 3 + 5
		var minutes = roundi(rounds * 1.5)
		node_dialog.get_node("lblInfo").text = "预计 " + str(rounds) + " 回合 | 约 " + str(minutes) + " 分钟"

func _on_click_btn_close() -> void:
	# 返回 false 表示取消
	close(false)

func _on_click_btn_go() -> void:
	# 保存数据到 session，供 pick_screen 读取
	var session = GdRoguelikeManager.game_session
	if session:
		session.set_ui_temp_data(_selected_difficulty, _seed)
	
	# 返回 true 表示确认
	close(true)