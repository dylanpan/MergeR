extends BaseEntity

# ============================================================
# 休息点实体基类（替代 BaseRestEntity.js）
# 提供完整的休息点生命周期：
#   init(meta) → on_init()
#   open() → on_open()
#   confirm() → on_confirm() → on_complete() → close
#   skip() → on_skip() → close
# ============================================================

class_name BaseRestEntity

func get_entity_type() -> int:
	return EntityType.REST

var rest_id: int = 0
var rest_type: String = ""
var _meta: Dictionary = {}
var _state: String = "init"  # init / opened / completed

func _init(p_rest_id: int = 0, p_type: String = ""):
	rest_id = p_rest_id
	rest_type = p_type
	
	var data_comp = DataComponent.new({"id": p_rest_id, "type": p_type})
	add_component(data_comp)

# ============ 生命周期公共方法 ============

func init(meta: Dictionary = {}) -> void:
	"""注入元数据配置，在创建后立即调用"""
	_meta = meta
	_state = "init"
	on_init()

func open() -> void:
	"""打开休息点，发送 UI 打开信号"""
	_state = "opened"
	on_open()
	GlobalEventBus.event_rest_open.emit(rest_id, get_ui_data())

func confirm() -> bool:
	"""确认使用休息功能"""
	if _state != "opened":
		return false
	
	on_confirm()
	_state = "completed"
	on_complete()
	GlobalEventBus.event_rest_confirm.emit()
	GlobalEventBus.event_rest_close.emit()
	return true

func skip() -> void:
	"""跳过休息点"""
	on_skip()
	GlobalEventBus.event_rest_skip.emit()
	GlobalEventBus.event_rest_close.emit()

func close() -> void:
	"""强制关闭"""
	GlobalEventBus.event_rest_close.emit()
	on_close()
	dispose()

func get_ui_data() -> Dictionary:
	"""获取 UI 展示数据，子类可重写"""
	return _meta

# ============ 生命周期钩子（子类重写） ============

func on_init():
	"""初始化回调"""
	pass

func on_open():
	"""打开回调"""
	pass

func on_confirm():
	"""确认使用回调"""
	pass

func on_skip():
	"""跳过回调"""
	pass

func on_complete():
	"""完成回调"""
	pass

func on_close():
	"""关闭回调"""
	pass

# ============ 原有 GD 兼容接口 ============

func on_enter() -> Dictionary:
	return get_ui_data()
