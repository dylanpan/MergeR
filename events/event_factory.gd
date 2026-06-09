extends Node

# ============================================================
# 事件工厂类（替代 EventFactory.js）
# 负责根据事件ID创建对应的事件实体实例，并注入元数据配置
# ============================================================

class_name EventFactory

# 注册表：存储事件ID到构造函数的映射
static var _event_registry: Dictionary = {}

# 初始化时注册内置事件
static func _static_init() -> void:
	_event_registry[70001] = func(id): return TreasureChestEvent.new(id)
	_event_registry[70002] = func(id): return HealFountainEvent.new(id)
	_event_registry[70003] = func(id): return RandomBuffEvent.new(id)
	_event_registry[70004] = func(id): return StartChoiceEvent.new(id)

static func create_event_entity(event_id: int, meta: Dictionary = {}) -> BaseEventEntity:
	if _event_registry.is_empty():
		_static_init()
	
	var factory = _event_registry.get(event_id, null)
	if not factory:
		GDLogger.warn("EventFactory: 未注册的事件ID " + str(event_id))
		return null
	
	var entity = factory.call(event_id) as BaseEventEntity
	if not entity:
		GDLogger.error("EventFactory: 创建事件实体失败 ID=" + str(event_id))
		return null
	
	# 注入元数据配置：若未提供 meta，从 MetaConsts 自动读取
	if meta.is_empty() and MetaConsts.has("gameEvents"):
		meta = MetaConsts.gameEvents.get(event_id, {})
	
	entity.init(meta)
	return entity

static func register_event_entity(event_id: int, class_ref) -> void:
	# 通过类引用的 new 方法动态创建实例
	if class_ref == null:
		GDLogger.warn("EventFactory.register_event_entity: class_ref 为空")
		return
	if _event_registry.has(event_id):
		GDLogger.warn("EventFactory.register_event_entity: 事件ID " + str(event_id) + " 已被注册，将被覆盖")
	
	_event_registry[event_id] = func(id): return class_ref.new(id)
	GDLogger.info("EventFactory: 注册事件 ID=" + str(event_id) + " 成功")
