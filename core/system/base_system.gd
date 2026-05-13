extends Node

# ============================================================
# 系统基类（替代 BaseSystem.js）
# ============================================================

class_name BaseSystem

# 系统阶段和优先级（由 SystemRegistry 设置）
var _phase: int = 0
var _priority: int = 0

func _init():
	pass

func dispose():
	pass

func update(dt: float):
	pass
