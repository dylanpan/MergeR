extends Node

# ============================================================
# 技能基类（替代 BaseSkill.js）
# 所有技能的父类，定义标准技能契约
# ============================================================

class_name BaseSkill

var skill_data: Dictionary = {}
var entity_id: String = ""
var is_active: bool = false

func _init(p_skill_data: Dictionary = {}):
	skill_data = p_skill_data

func execute(context: Dictionary = {}) -> void:
	on_execute(context)

func on_execute(context: Dictionary) -> void:
	push_error("Skill must implement on_execute() method")

func bind_entity(p_entity_id: String) -> void:
	entity_id = p_entity_id

# 注册事件监听（子类重写）
func _register_event_listener() -> void:
	pass

# 事件处理入口（由GlobalEventBus信号连接调用的适配方法）
func on_event(event_name: String, args: Dictionary = {}) -> void:
	if args.get("entityId", "") != entity_id:
		return
	execute(args)

# 连接到GlobalEventBus信号
func connect_to_bus(signal_name: String) -> void:
	if GlobalEventBus.has_signal(signal_name):
		GlobalEventBus.connect(signal_name, Callable(self, "_on_bus_event").bind(signal_name))

# 总线事件适配器
func _on_bus_event(args, signal_name: String) -> void:
	if args is Dictionary and args.get("entityId", "") != entity_id:
		return
	execute(args if args is Dictionary else {})

func dispose() -> void:
	is_active = false
	# 若在场景树内则断开所有连接
	if is_inside_tree():
		var connections = get_all_connections()
		for connection in connections:
			disconnect(connection.signal, connection.callable)
