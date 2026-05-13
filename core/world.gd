extends Node

# ============================================================
# World 核心类（替代 World.js）
# 管理所有系统和子管理器，作为游戏主循环入口
# ============================================================

var system_registry: SystemRegistry = null

# 子管理器（新架构）
var entity_manager: EntityManager = null
var entity_service: EntityService = null
var game_state_manager: GameStateManager = null
var inventory_manager: InventoryManager = null
var ui_root_manager: UIRootManager = null

func _init():
	system_registry = SystemRegistry.new()
	entity_manager = EntityManager.new()
	entity_service = EntityService.new(entity_manager)
	game_state_manager = GameStateManager.new()
	inventory_manager = InventoryManager.new()
	ui_root_manager = UIRootManager.new()

func create(node = null) -> void:
	# 使用 SystemRegistry 注册所有内置系统
	system_registry.register_builtin()
	WorldDataManager.set_world(self)
	WorldDataManager.set_entity_manager(entity_manager)
	BuffSystem.get_instance().init()
	
	if node:
		ui_root_manager.setup_from_node(node)

func get_systems() -> Array:
	return system_registry.get_all()

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
	game_state_manager.reset()
	WorldDataManager.set_init_flag(false)
