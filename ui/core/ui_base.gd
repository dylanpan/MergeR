extends Control
class_name UIBase

# ============================================================
# UI 基类 — 所有 UI 面板必须继承此类
# 提供统一的生命周期、动画、关闭等接口
# ============================================================

@export var ui_name: String = "unnamed"
@export var layer_name: String = "popup"
@export var close_on_overlay_click: bool = false  # 点击遮罩关闭（仅模态层有效）

# 信号：关闭时携带返回数据
signal closed(return_data)

# 动画配置
var _tween: Tween = null
@export var anim_in_duration: float = 0.3
@export var anim_out_duration: float = 0.2
@export var anim_in_type: int = 0  # 0: 立即, 1: 淡入, 2: 缩放弹入, 3: 上滑
@export var anim_out_type: int = 0 # 0: 立即, 1: 淡出, 2: 缩放淡出, 3: 下滑

# 生命周期（由 UIManager 调用）
func _ready():
	pass

func on_opened(params = null):
	# 界面打开后调用，可接收参数
	pass

func on_closed():
	# 界面关闭时调用，用于清理
	pass

# ==================== 动画接口 ====================

func animate_in():
	# 如果没有启用动画，立即显示
	if anim_in_type == 0:
		visible = true
		return
	
	# 初始化状态
	visible = true
	_kill_tween()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_OUT)
	
	match anim_in_type:
		1:  # 淡入
			modulate = Color(1, 1, 1, 0)
			_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), anim_in_duration)
		2:  # 缩放弹入
			scale = Vector2(0.5, 0.5)
			_tween.tween_property(self, "scale", Vector2(1, 1), anim_in_duration)
		3:  # 上滑
			var start_y = get_viewport_rect().size.y * 0.2
			position = Vector2(position.x, position.y + start_y)
			_tween.tween_property(self, "position", Vector2(position.x, position.y - start_y), anim_in_duration)


func animate_out():
	# 如果没有启用动画，立即消失
	if anim_out_type == 0:
		visible = false
		await get_tree().process_frame
		queue_free()
		return
	
	_kill_tween()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN)
	
	match anim_out_type:
		1:  # 淡出
			_tween.tween_property(self, "modulate", Color(1, 1, 1, 0), anim_out_duration)
		2:  # 缩放淡出
			_tween.tween_property(self, "scale", Vector2(0.5, 0.5), anim_out_duration)
		3:  # 下滑
			var slide_y = get_viewport_rect().size.y * 0.2
			_tween.tween_property(self, "position", Vector2(position.x, position.y + slide_y), anim_out_duration)
	
	# 等待动画完成
	await _tween.finished
	queue_free()


func _kill_tween():
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = null

# ==================== 关闭方法 ====================

# 关闭自身（通常由 UI 内部按钮调用）
func close(return_data = null):
	UIManager.close_ui(ui_name, return_data)
