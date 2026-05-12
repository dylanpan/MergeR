extends Resource

# ============================================================
# 组件基类（替代 BaseComponent.js）
# ============================================================

class_name BaseComponent

var comp_name: String = ""

func _init():
	comp_name = "BaseComponent"

func dispose():
	pass