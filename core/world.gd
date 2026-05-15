extends Node

# ============================================================
# World 核心类（替代 World.js）
# 管理所有系统和子管理器，作为游戏主循环入口
# ============================================================

var system_registry: SystemRegistry = null

# 实体管理层
var entity_manager: EntityManager = null
var entity_service: EntityService = null

# 服务层
var game_state_service: GameStateService = null
var inventory_service: InventoryService = null
var persistence_service: PersistenceService = null
var ui_root_service: UIRootService = null
var element_service: ElementService = null

func _init():
	system_registry = SystemRegistry.new()
	entity_manager = EntityManager.new()
	entity_service = EntityService.new(entity_manager)
	
	# 初始化服务层
	game_state_service = GameStateService.new()
	inventory_service = InventoryService.new()
	persistence_service = PersistenceService.new()
	ui_root_service = UIRootService.new()
	element_service = ElementService.new()

func create(node = null) -> void:
	# 使用 SystemRegistry 注册所有内置系统
	system_registry.register_builtin()
	# 将 World 引用注入到所有已注册系统
	system_registry.set_world(self)
	WorldDataManager.set_world(self)
	WorldDataManager.set_entity_manager(entity_manager)
	BuffSystem.get_instance().init()
	
	if node:
		ui_root_service.set_element_ui_root(node.get_element_ui_root() if node.has_method("get_element_ui_root") else null)
		ui_root_service.set_launcher_ui_root(node.get_launcher_ui_root() if node.has_method("get_launcher_ui_root") else null)
		ui_root_service.set_bullet_ui_root(node.get_bullet_ui_root() if node.has_method("get_bullet_ui_root") else null)
		ui_root_service.set_order_ui_root(node.get_order_ui_root() if node.has_method("get_order_ui_root") else null)
		ui_root_service.set_attack_ui_root(node.get_attack_ui_root() if node.has_method("get_attack_ui_root") else null)

func get_systems() -> Array:
	return system_registry.get_all()

# ==================== 主循环（基于 Phase 编排） ====================

func tick(dt: float = 0.0) -> void:
	"""
	游戏主循环，按 Phase 顺序执行所有系统。
	替代 roguelike_screen 中直接遍历 get_systems() 的方式。
	"""
	system_registry.update_phase(SystemRegistry.Phase.PRE_BATTLE, dt)
	system_registry.update_phase(SystemRegistry.Phase.BATTLE, dt)
	system_registry.update_phase(SystemRegistry.Phase.POST_BATTLE, dt)
	system_registry.update_phase(SystemRegistry.Phase.CLEANUP, dt)

# ==================== 便捷查询 API ====================

func query() -> EntityQuery:
	return entity_manager.query()

func query_type(type_val: int) -> EntityQuery:
	return entity_manager.query_type(type_val)

func get_entity(entity_id: String):
	return entity_manager.get_by_id(entity_id)

# ==================== 生命周期 ====================

func destroy() -> void:
	system_registry.dispose_all()
	entity_manager.clear_all()
	game_state_service.reset()
	inventory_service.reset()
	persistence_service.reset()
	ui_root_service.reset()
	WorldDataManager.set_init_flag(false)