extends Node

# ============================================================
# World 核心类（替代 World.js）
# 管理所有系统，作为游戏主循环入口
# ============================================================

var _systems: Array = []
var entity_manager: EntityManager = null

func _init():
	entity_manager = EntityManager.new()

func create(node = null) -> void:
	_create_systems()
	WorldDataManager.set_world(self)
	WorldDataManager.set_entity_manager(entity_manager)
	BuffSystem.get_instance().init()
	
	if node:
		var wdm = WorldDataManager
		# node is expected to have UI root references
		if node.has_method("get_element_ui_root"):
			wdm.add_element_ui_root(node.get_element_ui_root())
		if node.has_method("get_launcher_ui_root"):
			wdm.add_launcher_ui_root(node.get_launcher_ui_root())
		if node.has_method("get_bullet_ui_root"):
			wdm.add_bullet_ui_root(node.get_bullet_ui_root())
		if node.has_method("get_order_ui_root"):
			wdm.add_order_ui_root(node.get_order_ui_root())
		if node.has_method("get_attack_ui_root"):
			wdm.add_attack_ui_root(node.get_attack_ui_root())

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

func query() -> EntityQuery:
	return entity_manager.query()

func query_type(type_val: int) -> EntityQuery:
	return entity_manager.query_type(type_val)

func destroy() -> void:
	for system in _systems:
		system.dispose()
	_systems.clear()
	
	entity_manager.clear_all()
	WorldDataManager.set_init_flag(false)
