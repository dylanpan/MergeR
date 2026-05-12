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