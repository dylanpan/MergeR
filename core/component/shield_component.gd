extends BaseComponent

# ============================================================
# 护盾组件（替代 ShieldComponent.js）
# ============================================================

class_name ShieldComponent

var shield_points: float = 0.0
var max_shield: float = 0.0
var shield_type: int = 0

func _init(p_shield: float = 0, p_max: float = 0):
	comp_name = "Shield"
	shield_points = p_shield
	max_shield = p_max if p_max > 0 else p_shield

func add_shield(amount: float) -> void:
	shield_points = min(shield_points + amount, max_shield)

func reduce_shield(amount: float) -> float:
	var absorbed = min(shield_points, amount)
	shield_points -= absorbed
	return absorbed

func has_shield() -> bool:
	return shield_points > 0.0