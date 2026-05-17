extends Control
class_name BossUI

# Boss特殊UI（替代 BossUI.js）
# 管理Boss的阶段、血量、护盾、元素显示和特效
# 使用方式：
#   var ui = preload("res://ui/components/boss_ui.tscn").instantiate()
#   parent.add_child(ui)
#   ui.setup(entity)

var entity
var _is_initialized: bool = false

func setup(p_entity) -> void:
	entity = p_entity
	_init()
	
func _init() -> void:
	if _is_initialized:
		return
	_is_initialized = true
	_init_event()
	_init_ui()

func dispose() -> void:
	queue_free()

func _init_event() -> void:
	GlobalEventBus.event_update_game_over.connect(_on_game_over)
	GlobalEventBus.event_game_state.connect(_on_game_state)

func _init_ui() -> void:
	_init_health_bar()
	_init_phase_display()
	_init_shield_display()
	_init_element_display()
	_init_skill_display()

func _init_health_bar() -> void:
	if has_node("healthBar"):
		get_node("healthBar").visible = true

func _init_phase_display() -> void:
	if has_node("phaseDisplay"):
		get_node("phaseDisplay").visible = true
		if get_node("phaseDisplay") is Label:
			get_node("phaseDisplay").text = "第一阶段"

func _init_shield_display() -> void:
	if has_node("shieldDisplay"):
		get_node("shieldDisplay").visible = false

func _init_element_display() -> void:
	if has_node("elementDisplay"):
		get_node("elementDisplay").visible = true

func _init_skill_display() -> void:
	if has_node("skillDisplay"):
		get_node("skillDisplay").visible = true

func _on_game_state(data: Dictionary) -> void:
	if data.get("type", "") == "over":
		_on_game_over()

func _on_game_over() -> void:
	# 游戏结束时隐藏Boss UI
	visible = false
	
	# 重置显示状态
	if has_node("healthBar"):
		get_node("healthBar").visible = false
	if has_node("phaseDisplay"):
		get_node("phaseDisplay").visible = false
	if has_node("shieldDisplay"):
		get_node("shieldDisplay").visible = false
	if has_node("elementDisplay"):
		get_node("elementDisplay").visible = false
	if has_node("skillDisplay"):
		get_node("skillDisplay").visible = false
	
	_is_initialized = false
	entity = null
