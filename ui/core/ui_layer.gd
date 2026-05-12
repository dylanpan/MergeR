extends Node2D
class_name UILayer

# ============================================================
# UI 层级管理
# 每个 UILayer 对应一个独立的渲染层，管理该层内的所有 UI
# ============================================================

var config: UILayerConfig
var stack: Array[UIBase] = []
var overlay: ColorRect = null

var _canvas_layer: CanvasLayer = null
var _blocker: ColorRect = null


func setup(cfg: UILayerConfig):
	config = cfg
	
	# 创建 CanvasLayer 实现独立渲染层
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = cfg.z_index
	add_child(_canvas_layer)
	
	# 如果该层需要 blocking，创建全屏输入拦截器
	if cfg.block_input:
		_create_blocker(_canvas_layer)
	
	# 如果需要遮罩层
	if cfg.show_overlay:
		_create_overlay(_canvas_layer)
	
	# 监听窗口大小变化
	get_tree().root.size_changed.connect(_on_viewport_size_changed)


func add_to_layer(ui: UIBase):
	if ui.get_parent():
		ui.get_parent().remove_child(ui)
	
	_canvas_layer.add_child(ui)
	stack.append(ui)
	
	# 调整 Z 顺序：最新加入的排在顶层
	_reorder_stack()
	
	# 将 blocker 和 overlay 移到最前/最后
	_refresh_blocker_overlay_order()


func remove_from_layer(ui: UIBase, skip_free: bool = false):
	var idx = stack.find(ui)
	if idx != -1:
		stack.remove_at(idx)
		if ui.get_parent():
			ui.get_parent().remove_child(ui)
		if not skip_free:
			ui.queue_free()
		# 重新调整剩余 UI 的 Z 顺序
		_reorder_stack()
		_refresh_blocker_overlay_order()


func clear_layer():
	while stack.size() > 0:
		var ui = stack.pop_back()
		ui.queue_free()


func get_top_ui() -> UIBase:
	if stack.size() > 0:
		return stack[-1]
	return null


func _reorder_stack():
	# 按 stacking 顺序设置 z_index 值
	for i in range(stack.size()):
		stack[i].z_index = i


func _refresh_blocker_overlay_order():
	# 确保 blocker 在所有 UI 之上（拦截输入），overlay 在 UI 之下
	if _blocker:
		_blocker.move_to_front()
	if overlay:
		overlay.move_to_back()


func _create_blocker(parent: CanvasLayer):
	_blocker = ColorRect.new()
	_blocker.color = Color.TRANSPARENT
	_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_blocker.size = _get_viewport_size()
	_blocker.name = "InputBlocker"
	parent.add_child(_blocker)
	
	# 点击遮罩关闭顶层 UI
	_blocker.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var top_ui = get_top_ui()
			if top_ui and top_ui.close_on_overlay_click:
				UIManager.close_ui(top_ui.ui_name)
	)


func _create_overlay(parent: CanvasLayer):
	overlay = ColorRect.new()
	overlay.color = config.overlay_color
	overlay.size = _get_viewport_size()
	overlay.name = "Overlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 不拦截鼠标，由 blocker 负责
	parent.add_child(overlay)


func _on_viewport_size_changed():
	var new_size = _get_viewport_size()
	if _blocker:
		_blocker.size = new_size
	if overlay:
		overlay.size = new_size


func _get_viewport_size() -> Vector2:
	var root = get_tree().root
	if root:
		return root.size
	return Vector2(1920, 1080)