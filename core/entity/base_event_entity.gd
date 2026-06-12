extends BaseEntity

# ============================================================
# 事件实体基类（替代 BaseEventEntity.js）
# 提供完整的事件生命周期：
#   init(meta) → on_init()
#   open() → on_open()
#   select_option(option_id) → on_option_select(option_id) → on_complete()
#   close() → on_close()
# ============================================================

class_name BaseEventEntity

func get_entity_type() -> int:
	return EntityType.EVENT

var event_id: int = 0
var event_type: String = ""
var _meta: Dictionary = {}
var _state: String = "init"  # init / opened / completed
var _selected_option: int = -1

func _init(p_event_id: int = 0, p_type: String = ""):
	event_id = p_event_id
	event_type = p_type
	
	var data_comp = DataComponent.new({"id": p_event_id, "type": p_type})
	add_component(data_comp)

# ============ 生命周期公共方法 ============

func init(meta: Dictionary = {}) -> void:
	"""注入元数据配置，在创建后立即调用"""
	_meta = meta
	_state = "init"
	on_init()

func open() -> void:
	"""打开事件，发送 UI 打开信号"""
	_state = "opened"
	on_open()
	GlobalEventBus.event_round_update.emit({"type": "event_open", "eventId": event_id, "eventData": get_ui_data()})

func select_option(option_id: int) -> bool:
	"""处理选项选择，返回 true 表示事件完成"""
	if _state != "opened":
		return false
	
	_selected_option = option_id
	on_option_select(option_id)
	_state = "completed"
	on_complete()
	GlobalEventBus.event_round_update.emit({"type": "event_close"})
	return true

func close() -> void:
	"""强制关闭事件"""
	GlobalEventBus.event_round_update.emit({"type": "event_close"})
	on_close()
	dispose()

func get_ui_data() -> Dictionary:
	"""获取 UI 展示数据，子类可重写以附加额外信息"""
	return _meta

# ============ 生命周期钩子（子类重写） ============

func on_init():
	"""初始化回调：在此进行奖励预抽取、数值预计算"""
	pass

func on_open():
	"""打开回调：在此展示 UI 信息"""
	pass

func on_complete():
	"""完成回调：事件选择后的收尾逻辑"""
	pass

func on_close():
	"""关闭回调：清理资源"""
	pass

# ============ 原有的 GD 兼容接口（子类重写） ============

func on_enter() -> Dictionary:
	"""进入事件时调用，返回事件数据给 UI（兼容旧接口）"""
	return {"id": event_id, "type": event_type}

func on_option_select(option_id: int) -> void:
	"""选项选择回调（兼容旧接口，由 select_option 内部调用）"""
	pass
