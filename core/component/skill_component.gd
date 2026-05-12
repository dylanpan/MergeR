extends BaseComponent

# ============================================================
# 技能组件（替代 SkillComponent.js）
# ============================================================

class_name SkillComponent

var skills: Dictionary = {}  # skill_id -> skill_data
var cooldowns: Dictionary = {}  # skill_id -> remaining_cooldown

func _init():
	comp_name = "Skill"

func add_skill(skill_id: int, skill_data: Dictionary) -> void:
	skills[skill_id] = skill_data
	cooldowns[skill_id] = 0

func remove_skill(skill_id: int) -> void:
	skills.erase(skill_id)
	cooldowns.erase(skill_id)

func has_skill(skill_id: int) -> bool:
	return skills.has(skill_id)

func get_skill_data(skill_id: int) -> Dictionary:
	return skills.get(skill_id, {})

func is_skill_ready(skill_id: int) -> bool:
	return cooldowns.get(skill_id, 0) <= 0

func use_skill(skill_id: int) -> void:
	var skill_data = skills.get(skill_id, {})
	var cooldown = skill_data.get("cooldown", 1)
	cooldowns[skill_id] = cooldown

func reduce_cooldowns() -> void:
	for skill_id in cooldowns.keys():
		if cooldowns[skill_id] > 0:
			cooldowns[skill_id] -= 1

func reset_cooldowns() -> void:
	for skill_id in cooldowns.keys():
		cooldowns[skill_id] = 0

func dispose():
	skills.clear()
	cooldowns.clear()
	super.dispose()