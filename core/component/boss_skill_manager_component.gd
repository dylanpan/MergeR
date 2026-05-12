extends BaseComponent

# ============================================================
# Boss 技能管理组件（替代 BossSkillManagerComponent.js）
# ============================================================

class_name BossSkillManagerComponent

var active_skills: Array = []  # Array of BossSkillComponent
var all_skills: Array = []

func _init():
	comp_name = "BossSkillManager"

func init(skill_configs: Array) -> void:
	all_skills = []
	for config in skill_configs:
		var skill_comp = BossSkillComponent.new(config.get("skillId", 0), config.get("priority", 1))
		all_skills.append(skill_comp)

func activate_skills_for_phase(phase_id: String) -> void:
	active_skills = []
	for skill in all_skills:
		active_skills.append(skill)

func get_next_skill():
	var ready_skills = []
	for skill in active_skills:
		if skill.is_ready():
			ready_skills.append(skill)
	if ready_skills.is_empty():
		return null
	ready_skills.sort_custom(func(a, b): return a.priority < b.priority)
	var selected = ready_skills[0]
	selected.use()
	return selected

func tick_all() -> void:
	for skill in all_skills:
		skill.tick()