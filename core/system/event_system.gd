extends BaseSystem
class_name EventSystem

# ============================================================
# 事件系统（替代 EventSystem.js）
# 管理地图节点上的随机事件：创建、生命周期和调度
# 使用 BaseEventEntity 新生命周期框架
# ============================================================

var _cur_event_entity = null

func _init():
	pass

func dispose():
	if _cur_event_entity:
		_cur_event_entity.dispose()
		_cur_event_entity = null

func update(dt: float) -> void:
	pass

# 通过事件ID创建并打开事件（使用 EventFactory）
func open_event(event_id: int) -> bool:
	if _cur_event_entity:
		push_warning("EventSystem: 当前已有打开的事件")
		return false
	
	var event_entity = EventFactory.create_event_entity(event_id)
	if not event_entity:
		return false
	
	_cur_event_entity = event_entity
	event_entity.open()
	
	if _world:
		_world.entity_manager.register_entity(event_entity)
	return true

# 通过已有的实体触发事件（地图节点方式）
func trigger_event(entity) -> void:
	if not entity:
		return
	var event_data = entity.on_enter() if entity.has_method("on_enter") else {}
	_cur_event_entity = entity
	if _world:
		_world.entity_manager.register_entity(entity)
	GlobalEventBus.event_event_open.emit(entity.get_id(), event_data)

# 关闭当前事件
func close_current_event() -> void:
	if _cur_event_entity:
		_cur_event_entity.close()
		_cur_event_entity = null

# 处理用户选项选择（使用 BaseEventEntity.select_option 返回布尔值）
func resolve_option(entity, option_id: int) -> void:
	if not entity:
		return
	
	var result = false
	# 优先使用新生命周期方法 select_option（返回 bool）
	if entity.has_method("select_option"):
		result = entity.select_option(option_id)
	elif entity.has_method("on_option_select"):
		entity.on_option_select(option_id)
		result = true
	
	if result:
		_cur_event_entity = null
	GlobalEventBus.event_event_close.emit()
