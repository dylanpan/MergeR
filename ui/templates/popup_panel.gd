extends UIBase
class_name PopupPanelTemplate

# ============================================================
# 通用弹窗模板
# 使用方式：
#   var panel = preload("res://ui/templates/popup_panel.gd").new()
#   panel.setup("标题", "内容文本", callback_func)
#   或者注册到 UIManager 后调用 UIManager.open_ui("popup_panel", {...})
# ============================================================

var _callback: Callable
var _title: String = ""
var _content_text: String = ""

func _ready() -> void:
	layer_name = "popup"
	ui_name = "popup_panel"

func on_opened(params = null) -> void:
	if params:
		_title = params.get("title", "")
		_content_text = params.get("content", "")
		_callback = params.get("callback", Callable())
		if params.get("confirm_callback") is Callable:
			_callback = params["confirm_callback"]
	
	_init_ui()

func on_closed() -> void:
	_callback = Callable()

# 快捷设置方法（直接脚本实例化时使用）
func setup(title: String, content: String, callback: Callable = Callable()) -> void:
	_title = title
	_content_text = content
	_callback = callback
	_init_ui()

func _init_ui() -> void:
	# 创建背景遮罩 — 如果没有场景节点，动态创建 UI
	if get_child_count() == 0:
		_create_default_layout()

func _create_default_layout() -> void:
	# 设置自身锚点全屏
	size = get_viewport_rect().size
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# 背景板
	var bg = Panel.new()
	bg.name = "bg"
	bg.anchor_left = 0.3
	bg.anchor_top = 0.3
	bg.anchor_right = 0.7
	bg.anchor_bottom = 0.7
	bg.color = Color(0.2, 0.2, 0.3, 0.95)
	add_child(bg)
	
	# 标题
	var title_label = Label.new()
	title_label.name = "lblTitle"
	title_label.text = _title if _title else "提示"
	title_label.anchor_left = 0.05
	title_label.anchor_top = 0.05
	title_label.anchor_right = 0.95
	title_label.anchor_bottom = 0.2
	bg.add_child(title_label)
	
	# 内容文本
	var content_label = Label.new()
	content_label.name = "lblContent"
	content_label.text = _content_text if _content_text else "确认执行此操作？"
	content_label.anchor_left = 0.05
	content_label.anchor_top = 0.25
	content_label.anchor_right = 0.95
	content_label.anchor_bottom = 0.7
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	bg.add_child(content_label)
	
	# 确认按钮
	var confirm_btn = Button.new()
	confirm_btn.name = "btnConfirm"
	confirm_btn.text = "确认"
	confirm_btn.anchor_left = 0.7
	confirm_btn.anchor_top = 0.75
	confirm_btn.anchor_right = 0.95
	confirm_btn.anchor_bottom = 0.95
	confirm_btn.pressed.connect(_on_confirm)
	bg.add_child(confirm_btn)
	
	# 取消按钮
	var cancel_btn = Button.new()
	cancel_btn.name = "btnCancel"
	cancel_btn.text = "取消"
	cancel_btn.anchor_left = 0.05
	cancel_btn.anchor_top = 0.75
	cancel_btn.anchor_right = 0.3
	cancel_btn.anchor_bottom = 0.95
	cancel_btn.pressed.connect(_on_cancel)
	bg.add_child(cancel_btn)

func _on_confirm() -> void:
	if _callback.is_valid():
		_callback.call(true)
	close(true)

func _on_cancel() -> void:
	if _callback.is_valid():
		_callback.call(false)
	close(false)