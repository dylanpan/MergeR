extends BaseSystem

# ============================================================
# 休息系统（替代 RestSystem.js）
# 管理休息点的恢复、升级等功能
# ============================================================

func _init():
	pass

func dispose():
	pass

func update(dt: float) -> void:
	pass

func open_rest(entity) -> void:
	if not entity:
		return
	var rest_data = entity.on_enter() if entity.has_method("on_enter") else {}
	GlobalEventBus.event_rest_open.emit(entity.get_id(), rest_data)

func confirm_rest(entity) -> void:
	if entity and entity.has_method("on_confirm"):
		entity.on_confirm()
	GlobalEventBus.event_rest_confirm.emit()
	GlobalEventBus.event_rest_close.emit()

func skip_rest(entity) -> void:
	if entity and entity.has_method("on_skip"):
		entity.on_skip()
	GlobalEventBus.event_rest_skip.emit()
	GlobalEventBus.event_rest_close.emit()