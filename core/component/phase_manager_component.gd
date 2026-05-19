extends BaseComponent

# ============================================================
# 阶段管理组件（替代 PhaseManagerComponent.js）
# 管理 Boss 的阶段转换
# ============================================================

class_name PhaseManagerComponent

var phases: Array = []
var current_phase_index: int = 0
var current_phase: Dictionary = {}
var phase_transitioning: bool = false
var transition_timer: float = 0.0
var transition_duration: float = 2.0
var entity_id: String = ""

func _init():
	comp_name = "PhaseManager"

func init(phase_configs: Array, p_entity_id: String) -> void:
	phases = []
	var _world = ClearRoguelikeManager.get_world()
	var _config = _world.config_service if _world and _world.config_service else null
	for config in phase_configs:
		var phase_id = config.get("phaseId", "")
		var skill_id = config.get("skills", [{}])[0].get("skillId", 0)
		var phase_config = _config.get_skill(skill_id) if _config else {}
		phases.append({
			"id": phase_id,
			"hpThreshold": config.get("hpThreshold", 1.0),
			"skills": config.get("skills", []),
		})
	current_phase_index = 0
	current_phase = phases[0] if not phases.is_empty() else {}
	entity_id = p_entity_id

func update_phase(dt: float, current_hp_ratio: float) -> void:
	if phase_transitioning:
		transition_timer += dt
		if transition_timer >= transition_duration:
			phase_transitioning = false
			transition_timer = 0
			_apply_phase_effects(current_phase)
		return
	
	for i in range(phases.size()):
		var phase = phases[i]
		if current_hp_ratio <= phase.get("hpThreshold", 0) and i > current_phase_index:
			_start_phase_transition(i)
			break

func _start_phase_transition(phase_index: int) -> void:
	current_phase_index = phase_index
	current_phase = phases[phase_index]
	phase_transitioning = true
	transition_timer = 0.0

func _apply_phase_effects(phase: Dictionary) -> void:
	var skills = phase.get("skills", [])
	GlobalEventBus.event_on_boss_phase_change.emit(entity_id, phase.get("id", ""))

func get_current_phase_id() -> String:
	return current_phase.get("id", "")