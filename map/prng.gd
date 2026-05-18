extends Node

# ============================================================
# 可复现伪随机数生成器（替代 Prng.js - Mulberry32算法）
# ============================================================

class_name Prng

var _state: int = 0

func _init(seed_value: int = 0):
	_state = seed_value

func set_seed(seed_value: int) -> void:
	_state = seed_value

func next_float() -> float:
	_state += 0x6D2B79F5
	var t = _state
	t = (t ^ (t >> 15)) * (1 | t)
	t = (t ^ (t >> 7)) * (1 | t)
	t ^= (t >> 15)
	return (t & 0xFFFFFFFF) as float / 4294967296.0

func next_int(min_val: int, max_val: int) -> int:
	return min_val + int(next_float() * (max_val - min_val + 1))

func random_choice(array: Array):
	if array.is_empty():
		return null
	return array[next_int(0, array.size() - 1)]

func weighted_random_choice(items: Array, weights: Array):
	if items.is_empty() or weights.is_empty():
		return null
	if items.size() != weights.size():
		return null
	
	var total_weight = 0.0
	for w in weights:
		total_weight += w
	
	var roll = next_float() * total_weight
	
	for i in range(items.size()):
		roll -= weights[i]
		if roll <= 0:
			return items[i]
	
	return items[-1]

func shuffle(array: Array) -> Array:
	var result = array.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j = next_int(0, i)
		var temp = result[i]
		result[i] = result[j]
		result[j] = temp
	return result
