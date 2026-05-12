extends BaseComponent

# ============================================================
# 元素变化组件（替代 ElementChangeComponent.js）
# ============================================================

class_name ElementChangeComponent

var original_element: int = 0
var current_element: int = 0
var change_rounds: int = 0
var max_changes: int = 1
var change_count: int = 0

func _init(p_element: int = 0):
	comp_name = "ElementChange"
	original_element = p_element
	current_element = p_element

func change_to(new_element: int, rounds: int = 1) -> void:
	if change_count < max_changes:
		current_element = new_element
		change_rounds = rounds
		change_count += 1

func reset() -> void:
	current_element = original_element
	change_rounds = 0

func on_round_end() -> void:
	if change_rounds > 0:
		change_rounds -= 1
		if change_rounds <= 0:
			reset()