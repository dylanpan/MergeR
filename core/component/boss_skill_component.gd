extends BaseComponent

# ============================================================
# Boss 技能组件（替代 BossSkillComponent.js）
# ============================================================

class_name BossSkillComponent

var skill_id: int = 0
var skill_data: Dictionary = {}
var cooldown: int = 0
var current_cooldown: int = 0
var priority: int = 1

func _init(p_skill_id: int = 0, p_priority: int = 1):
	comp_name = "BossSkill"
	skill_id = p_skill_id
	skill_data = MetaConsts.skills.get(p_skill_id, {})
	cooldown = skill_data.get("cooldown", 1)
	priority = p_priority

func is_ready() -> bool:
	return current_cooldown <= 0

func use() -> void:
	current_cooldown = cooldown

func tick() -> void:
	if current_cooldown > 0:
		current_cooldown -= 1