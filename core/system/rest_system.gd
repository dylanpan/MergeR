extends BaseSystem

# ============================================================
# 休息系统（替代 RestSystem.js）
# 管理休息点的恢复、升级等功能
# 中央状态管理，确保同一时间只有一个休息点活跃
# ============================================================

class_name RestSystem

var _current_rest = null

func _init():
	pass

func dispose():
	if _current_rest:
		_current_rest.dispose()
		_current_rest = null

func update(dt: float) -> void:
	pass

func open_rest(entity) -> void:
	if not entity:
		return
	
	# 关闭当前活跃的休息点（若存在）
	if _current_rest and _current_rest != entity:
		_current_rest.close()
	
	_current_rest = entity
	
	# 使用新生命周期 open 方法（若存在），否则 fallback on_enter
	if entity.has_method("open"):
		entity.open()
	elif entity.has_method("on_enter"):
		var rest_data = entity.on_enter()
		GlobalEventBus.event_rest_open.emit(entity.get_id(), rest_data)

func confirm_rest(entity) -> void:
	if not entity:
		return
	
	# 优先使用新生命周期 confirm 方法（返回 bool）
	if entity.has_method("confirm"):
		entity.confirm()
	elif entity.has_method("on_confirm"):
		entity.on_confirm()
		GlobalEventBus.event_rest_confirm.emit()
		GlobalEventBus.event_rest_close.emit()
	
	_current_rest = null

func skip_rest(entity) -> void:
	if not entity:
		return
	
	# 优先使用新生命周期 skip 方法
	if entity.has_method("skip"):
		entity.skip()
	elif entity.has_method("on_skip"):
		entity.on_skip()
		GlobalEventBus.event_rest_skip.emit()
		GlobalEventBus.event_rest_close.emit()
	
	_current_rest = null
