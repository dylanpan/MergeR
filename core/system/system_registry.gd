class_name SystemRegistry

# ============================================================
# 系统注册表
# 按阶段/优先级管理系统，替代 World._create_systems 硬编码
# ============================================================

enum Phase {
	INIT = 0,           # 初始化阶段
	PRE_BATTLE = 10,    # 战前阶段
	BATTLE = 20,        # 战斗阶段
	POST_BATTLE = 30,   # 战后阶段
	TICK = 40,          # 每 tick 阶段
	CLEANUP = 100,      # 清理阶段
}

var _systems: Array = []

# 按阶段分组的系统列表
var _systems_by_phase: Dictionary = {}

# World 引用，注册时注入给每个系统
var _world: World = null

func _init():
	for phase in Phase.values():
		_systems_by_phase[phase] = []

# ==================== 设置 ====================

func set_world(world: World) -> void:
	_world = world
	# 有世界后推送到已注册的系统
	for system in _systems:
		system._world = world

# ==================== 注册 ====================

func register(system: BaseSystem, phase: int = Phase.TICK, priority: int = 0) -> void:
	if not system:
		return
	system._phase = phase
	system._priority = priority
	if _world:
		system._world = _world
	_systems.append(system)
	_systems_by_phase[phase].append(system)

func register_builtin() -> void:
	"""注册所有内置系统"""
	register(BuffSystem.get_instance(), Phase.PRE_BATTLE, 0)
	register(CountDownStepSystem.new(), Phase.PRE_BATTLE, 10)
	register(BattleSystem.new(), Phase.BATTLE, 0)
	register(RoundSystem.new(), Phase.POST_BATTLE, 0)
	register(ShopSystem.new(), Phase.POST_BATTLE, 10)
	# register(EventSystem.new(), Phase.POST_BATTLE, 20)
	# register(RestSystem.new(), Phase.POST_BATTLE, 30)

# ==================== 查询 ====================

func get_all() -> Array:
	return _systems.duplicate()

func get_by_phase(phase: int) -> Array:
	return _systems_by_phase.get(phase, []).duplicate()

func has_type(system_class) -> bool:
	for system in _systems:
		if is_instance_of(system, system_class):
			return true
	return false

# ==================== 生命周期 ====================

func init_all() -> void:
	for system in _systems:
		if system.has_method("init") and not system.has_method("get_instance"):
			system.init()

func dispose_all() -> void:
	for system in _systems:
		if system.has_method("dispose"):
			system.dispose()
	_systems.clear()
	for phase in Phase.values():
		_systems_by_phase[phase] = []

func update_phase(phase: int, dt: float) -> void:
	var systems = _systems_by_phase.get(phase, [])
	for system in systems:
		system.update(dt)