extends Node

# ============================================================
# World 核心类（替代 World.js）
# 管理所有系统和子管理器，作为游戏主循环入口
# ============================================================

var _systems: Array = []

# 子管理器（新架构）
var entity_manager: EntityManager = null
var entity_service: EntityService = null
var game_state_manager: GameStateManager = null
var inventory_manager: InventoryManager = null
var ui_root_manager: UIRootManager = null

func _init():
	entity_manager = EntityManager.new()
	entity_service = EntityService.new(entity_manager)
	game_state_manager = GameStateManager.new()
	inventory_manager = InventoryManager.new()
	ui_root_manager = UIRootManager.new()

func create(node = null) -> void:
	_create_systems()
	WorldDataManager.set_world(self)
	WorldDataManager.set_entity_manager(entity_manager)
	BuffSystem.get_instance().init()
	
	if node:
		ui_root_manager.setup_from_node(node)

func _create_systems() -> void:
	var buff_system = BuffSystem.get_instance()
	_systems.append(buff_system)
	
	var count_down_step_system = CountDownStepSystem.new()
	_systems.append(count_down_step_system)
	
	var battle_system = BattleSystem.new()
	_systems.append(battle_system)
	
	var round_system = RoundSystem.new()
	_systems.append(round_system)
	
	var shop_system = ShopSystem.new()
	_systems.append(shop_system)
	
	var event_system = EventSystem.new()
	_systems.append(event_system)
	
	var rest_system = RestSystem.new()
	_systems.append(rest_system)

func get_systems() -> Array:
	return _systems

# ==================== 便捷查询 API ====================

func query() -> EntityQuery:
	return entity_manager.query()

func query_type(type_val: int) -> EntityQuery:
	return entity_manager.query_type(type_val)

func get_entity(entity_id: String):
	return entity_manager.get_by_id(entity_id)

# ==================== 生命周期 ====================

func destroy() -> void:
	for system in _systems:
		system.dispose()
	_systems.clear()
	
	entity_manager.clear_all()
	game_state_manager.reset()
	WorldDataManager.set_init_flag(false)
